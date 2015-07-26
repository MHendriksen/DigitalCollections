class Kor::Graph
  
  # Constructor
  
  def initialize(options = {})
    @options = options
  end
  
  
  # Main

  def find_paths(specs = [])
    if specs.size > 2
      db = ActiveRecord::Base.connection

      query = []
      fields = []
      conditions = []
      binds = []

      specs.each_with_index do |spec, i|
        index = i / 2

        if i == 0
          fields << "es_#{index}.id AS es_#{index}_id"
          fields << "es_#{index}.kind_id AS es_#{index}_kind_id"
          fields << "es_#{index}.name AS es_#{index}_name"
          query << "JOIN entities AS es_#{index} ON es_#{index}.id = rels_#{index}.from_id"

          if spec['id']
            value = [spec['id']] if spec['id'].is_a?(String)
            conditions << "es_#{index}.id IN ?"
            binds << value
          end
        elsif i == 1
          fields << "rels_#{index}.id AS rels_#{index}_id"
          fields << "rels_#{index}.relation_id AS rels_#{index}_relation_id"
          fields << "rs_#{index}.name AS rs_#{index}_name"
          fields << "rs_#{index}.reverse_name AS rs_#{index}_reverse_name"
          fields << "rels_#{index}.reverse AS rels_#{index}_reverse"
          query << "JOIN relations AS rs_#{index} ON rels_#{index}.relation_id = rs_#{index}.id"

          if spec['name']
            rels = Relation.where(:name => spec['name']).pluck(:id)
            reverse_rels = Relation.where(:reverse_name => spec['name']).pluck(:id)
            name_conditions = []
            if rels.present?
              name_conditions << "(rels_#{index}.relation_id IN ? AND NOT rels.#{index}.reverse)"
              binds << rels
            end
            if reverse_rels.present?
              name_conditions << "(rels_#{index}.relation_id IN ? AND rels.#{index}.reverse)"
              binds << rels
            end
            conditions << name_conditions.join(' OR ')
          end
        else
          if i % 2 == 0
            fields << "es_#{index}.id AS es_#{index}_id"
            fields << "es_#{index}.kind_id AS es_#{index}_kind_id"
            fields << "es_#{index}.name AS es_#{index}_name"
            query << "JOIN entities AS es_#{index} ON es_#{index}.id = rels_#{index - 1}.to_id"            

            if spec['id']
              value = [spec['id']] if spec['id'].is_a?(String)
              conditions << "es_#{index}.id IN ?"
              binds << value
            end
          else
            fields << "rels_#{index}.id AS rels_#{index}_id"
            fields << "rels_#{index}.relation_id AS rels_#{index}_relation_id"
            fields << "rs_#{index}.name AS rs_#{index}_name"
            fields << "rs_#{index}.reverse_name AS rs_#{index}_reverse_name"
            fields << "rels_#{index}.reverse AS rels_#{index}_reverse"
            query << "JOIN directed_relationships AS rels_#{index} ON es_#{index}.id = rels_#{index}.from_id"
            query << "JOIN relations AS rs_#{index} ON rels_#{index}.relation_id = rs_#{index}.id"
            
            if spec['name']
              rels = Relation.where(:name => spec['name']).pluck(:id)
              reverse_rels = Relation.where(:reverse_name => spec['name']).pluck(:id)
              name_conditions = []
              if rels.present?
                name_conditions << "(rels_#{index}.relation_id IN ? AND NOT rels.#{index}.reverse)"
                binds << rels
              end
              if reverse_rels.present?
                name_conditions << "(rels_#{index}.relation_id IN ? AND rels.#{index}.reverse)"
                binds << rels
              end
              conditions << name_conditions.join(' OR ')
            end
          end
        end
      end

      fields = fields.join(', ')
      init = ["SELECT #{fields} FROM directed_relationships AS rels_0"]

      query = (init + query).join("\n")
      conditions = conditions.map{|c| "(#{c})"}.join(" AND ")

      final = "#{query}" + (conditions.present? ? " WHERE #{conditions}" : "")
      puts final

      db.select_all(final).map do |r|
        specs.each_with_index.map do |spec, i|
          index = i / 2

          if i % 2 == 0
            {
              'id' => r["es_#{index}_id"]
            }
          else
            {
              'id' => r["rels_#{index}_id"],
              'relation_id' => r["rels_#{index}_relation_id"],
              'relation_name' => r["rs_#{index}_name"],
              'relation_reverse_name' => r["rs_#{index}_reverse_name"],
              'reverse' => !!r["rels_#{index}_reverse"]
            }
          end
        end
      end
    else
      []
    end
  end
  
  def search(type, options = {})
    Kor::Graph::Search.create(type, user, options)
  end
  
  def results_from(object)
    Kor::Graph::Search::Result.from(object)
  end
  
  
  # Accessors
  
  def user
    @options[:user]
  end
  
end
