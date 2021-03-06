class Medium < ActiveRecord::Base

  has_one :entity

  # -------------------------------------------------------------- paperclip ---
  def self.media_data_dir
    if Rails.env == 'production'
      "#{Rails.root}/data/media"
    else
      "#{Rails.root}/data/media.#{Rails.env}"
    end
  end
  
  has_attached_file :document, 
    path: "#{media_data_dir}/:style/:id_partition/document.:style_extension",
    url: "/media/images/:style/:id_partition/document.:style_extension",
    default_url: "/media/images/:style/:id_partition/image.:style_extension?:style_timestamp",
    styles: lambda {|attachment| attachment.instance.custom_styles},
    processors: lambda {|instance| instance.processors}
    
  has_attached_file :image,
    :path => "#{media_data_dir}/:style/:id_partition/image.:style_extension",
    :url => "/media/images/:style/:id_partition/image.:style_extension",
    :default_url => lambda {|attachment| attachment.instance.dummy_url},
    :styles => {
      :icon => ['80x80>', :jpg],
      :thumbnail => ['140x140>', :jpg],
      :preview => ['300x300>', :jpg],
      :screen => ['800x800>', :jpg],
      :normal => ['1440x1440>', :jpg]
    }

  process_in_background :document
  process_in_background :image

  def custom_styles
    result = {}

    if document.present?
      ct = document.content_type
      if ct.match(/^(video\/|application\/x-shockwave-flash|application\/mp4)/)
        result.merge!(
          mp4: {format: :mp4, content_type: 'video/mp4'},
          ogg: {format: :ogv, content_type: 'video/ogg'},
          webm: {format: :webm, content_type: 'video/webm'}
        )
      end
      if ct.match(/^audio\//)
        result.merge!(
          mp3: {format: :mp3, content_type: 'audio/mp3'},
          ogg: {format: :ogg, content_type: 'audio/ogg'}
        )
      end
    end

    result
  end

  def processors
    if document.present?
      ct = document.content_type
      return [:video] if ct.match(/^(video\/|application\/x-shockwave-flash|application\/mp4)/)
      return [:audio] if ct.match(/^audio\//)
    end
      
    []
  end

  
  # TODO: fix for audio case or remove if not used
  def presentable?
    self.content_type.match /^(image|video|application\/x-shockwave-flash|application\/mp4)/
  end
  
  def kind
    Kind.medium_kind
  end
  
  before_validation do |m|
    if m.document.file? && m.document.content_type.match(/^image\//)
      unless m.image.file?
        m.image = m.document
        m.document.clear
      end
    end
    
    if file = (m.to_file || m.to_file(:image))
      m.datahash = Digest::SHA1.hexdigest(file.read)
    end
  end
  
  after_destroy do |medium|
    medium.custom_styles.each do |name, config|
      file = medium.custom_style_path(name)
      FileUtils.rm(file) if File.exists?(file)
    end
  end
  
  
  # Validation

  validates_attachment :image, content_type: {content_type: /^image\/.+$/, if: Proc.new{|medium| medium.image.file?}}
  validates_attachment :document, presence: {unless: Proc.new{|medium| medium.image.file?}, message: :file_must_be_set} 
  validates :datahash, uniqueness: {:message => :file_exists}
  
  validate :validate_no_two_images
  validate :validate_file_size
  
  def validate_no_two_images
    if document.content_type && image.content_type
      if document.content_type.match(/^image\//) && image.content_type.match(/^image\//)
        errors.add :base, :no_two_images
      end
    end
  end

  def validate_file_size
    max_mb = Kor.config["app.max_file_upload_size"].to_f
    max_bytes = max_mb * 1024**2

    if image_file_size.present? and image_file_size > max_bytes
      errors.add :image_file_size, :file_size_less_than, :value => max_mb
    end

    if document_file_size.present? and document_file_size > max_bytes
      errors.add :document_file_size, :file_size_less_than, :value => max_mb
    end
  end
  
  
  # Paperclip
  
  def to_file(attachment = :document, style = :original)
    path = if attachment == :document
      document.staged_path || document.path
    else
      image.staged_path || image.path(style)
    end

    if path && File.exists?(path)
      File.open(path)
    end
  end

  def content_type(style = :original)
    if style == :original
      document.content_type || image.content_type
    elsif image_style?(style)
      "image/jpg"
    else
      custom_styles[style.to_sym][:content_type]
    end.downcase
  end
  
  def file_size
    original.size
  end
  
  def data(style = :original)
    if style == :original
      document.file? ? to_file(:document, style).read : to_file(:iamge, style).read
    elsif image_style?(style)
      File.read path(style)
    else
      custom_style_data(style)
    end
  end
  
  def original
    document.file? ? document : image
  end
  
  def original_extension
    File.extname(original.original_filename).gsub('.', '').downcase
  end
  
  def style_extension(style = :original)
    (document.styles[style] || image.styles[style] || {})[:format]
  end
  
  def download_filename(style = :original)
    if style == :original
      a, b = content_type.split('/')
      if a == 'image'
        "#{entity.id}.#{style}.#{b}"
      else
        "#{entity.id}.#{style}.#{original_extension}"
      end
    elsif image_style?(style)
      "#{entity.id}.#{style}.#{style_extension(style)}"
    else
      "#{entity.id}.#{style}.#{custom_styles[style.to_sym][:file_extension]}"
    end
  end
  
  def ids
    ("%09d" % id).scan(/\d{3}/).join('/')
  end
  
  def custom_style_path(style)
    document.path(style.to_sym)
  end
  
  def custom_style_url(style)
    document.url(style.to_sym)
  end
  
  def custom_style_data(style)
    File.read custom_style_path(style.to_sym)
  end
  
  def image_style?(style)
    image.styles.keys.include? style
  end
  
  def url(style = :original)
    if Rails.env.development? && !ENV['SHOW_MEDIA']
      dummy_url
    else
      result = if style == :original
        document.url(:original)
      elsif image_style?(style)
        image.url(style)
      else
        custom_style_url(style)
      end

      result.present? ? result.gsub(/%3F/, '?') : result
    end
  end
  
  def path(style = :original)
    if style == :original
      document.path(:original) || image.path(:original)
    elsif image_style?(style)
      if image.path(style) && File.exists?(image.path(style))
        image.path(style)
      else
        dummy_path
      end
    else
      custom_style_path(style)
    end
  end

  def dummy_path
    self.class.dummy_path(content_type)
  end

  def self.dummy_path(content_type)
    "#{Rails.root}/public#{self.dummy_url content_type}"
  end

  def dummy_url
    self.class.dummy_url(content_type)
  end
  
  def self.dummy_url(content_type)
    group, type = content_type.split('/').map{|t| t.gsub /\//, '_'}
  
    dir = "#{Rails.root}/public/content_types"
    group_dir = "#{dir}/#{group}"

    if File.exists?("#{group_dir}/#{type}.gif")
      "/content_types/#{group}/#{type}.gif"
    elsif File.exists?("#{group_dir}.gif")
      "/content_types/#{group}.gif"
    else
      "/content_types/default.gif"
    end
  end
  
  def uri=(value)
    self[:original_url] = value
    
    u = URI.parse value
    case u
      when URI::Generic
        if u.scheme == 'file'
          self.document = File.open(u.path)
        else
          raise "The file scheme is the only allowed generic scheme"
        end
      else
        self.document = u
    end
  end

  def human_content_type
    group, type = content_type.split('/')
    I18n.t(type, :scope => ['mimes', group], :default => content_type)
  end

  def document=(value)
    document.assign(value)

    if value
      ct = MIME::Types.type_for(document.original_filename).first
      self.document_content_type = ct.to_s if ct
    end
  end
  
end
