require "tmpdir"

module Kor::Auth

  def self.authenticate(username, password)
    user = User.authenticate username, password
    return true if user

    Dir.mktmpdir do |dir|
      File.open "#{dir}/username.txt", "w" do |f|
        f.write username
      end
      File.open "#{dir}/password.txt", "w" do |f|
        f.write password
      end

      script_sources.each do |method, c|
        command = "bash -c \"#{c["script"]}\""
        status = Bundler.with_clean_env do
          system(
            {
              "KOR_USERNAME_FILE" => "#{dir}/username.txt",
              "KOR_PASSWORD_FILE" => "#{dir}/password.txt",
              "KOR_USERNAME" => username,
              "KOR_PASSWORD" => password
            },
            "#{command} > #{dir}/stdout.log 2> #{dir}/error.log"
          )
        end
        data = File.read("#{dir}/stdout.log")

        if status
          return JSON.parse(data).merge(
            :parent_username => c["map_to"]
          )
        else
          error = File.read "#{dir}/error.log"
          Rails.logger.warn("AUTH script error: #{error}")
          Rails.logger.warn("AUTH script output: #{data}")
        end
      end
    end

    false
  end

  def self.env_login(env)
    Rails.logger.info "environment auth with env: #{env.inspect}"

    env_sources.each do |key, source|
      source['user'].each do |ku|
        source['mail'].each do |km|
          Rails.logger.info "trying attributes user:#{ku} and mail:#{km}"

          username = env[ku]
          mail = env[km]

          if username && mail
            Rails.logger.info "user found #{username} (#{mail})"

            full_name = nil
            source['full_name'].each do |kf|
              full_name ||= env[kf]
            end

            if s = source['splitter']
              username = username.split(Regexp.new(s)).first
              mail = mail.split(Regexp.new(s)).first
              full_name = full_name.split(Regexp.new(s)).first if full_name
            end
            
            data = {
              parent_username: source['map_to'],
              email: mail,
              full_name: full_name
            }

            Rails.logger.info "authorizing user #{username} with data #{data.inspect}"
            return authorize(username, data)
          else
            Rails.logger.info "no values for username and/or mail found: values found: #{username}/#{mail}"
            false
          end
        end
      end
    end

    false
  end

  def self.script_sources
    (Kor.config['auth.sources'] || []).select do |key, source|
      type = source['type'] || 'script'
      type == 'script'
    end
  end

  def self.env_sources
    (Kor.config['auth.sources'] || []).select do |key, source|
      source['type'] == 'env'
    end
  end

  def self.authorize(username, additional_attributes = true)
    user = User.includes(:groups).find_or_initialize_by(:name => username)

    if additional_attributes.is_a?(Hash)
      user.assign_attributes additional_attributes
    end

    if user.save
      user
    else
      if user.new_record?
        Rails.logger.info "user couldn't be created: #{user.errors.full_messages.inspect}"
        nil
      else
        Rails.logger.info "user couldn't be updated: #{user.errors.full_messages.inspect}"

        if Kor.config['auth.fail_on_update_errors']
          Rails.logger.info "authentication failed due to update errors"
          nil
        else
          Rails.logger.info "allowing authentication despite update errors"
          user
        end
      end
    end
  end
  
  def self.login(username, password)
    if attributes = authenticate(username, password)
      authorize(username, attributes)
    end
  end

  def self.groups(user)
    if user ||= User.guest
      user.parent.present? ? user.groups + user.parent.groups : user.groups
    else
      []
    end
  end

  def self.authorized_collections(user, policies = :view)
    user ||= User.guest

    result = Grant.where(
      :credential_id => groups(user).map{|c| c.id}, 
      :policy => policies
    ).group(:collection_id).count

    Collection.where(:id => result.keys).to_a
  end

  def self.authorized_credentials(collection, policy = :view)
    collection.grants.where(policy: policy).map do |grant|
      grant.credential
    end
  end
  
  def self.allowed_to?(user, policy = :view, collections = nil, options = {})
    collections ||= Collection.all.to_a
    user ||= User.guest
    policy = Collection.policies if policy == :all
    
    options.reverse_merge!(:required => :all)
    collections = if collections.is_a?(Collection)
      [collections]
    else
      collections.to_a
    end
    collections = collections.reject{|c| c.nil?}
    
    result = Grant.where(
      :credential_id => groups(user).map{|c| c.id},
      :policy => policy,
      :collection_id => collections.map{|c| c.id}
    ).group(:collection_id).count
    
    if options[:required] == :all
      result.keys.size == collections.size
    else
      result.keys.size > 0
    end
  end

end
