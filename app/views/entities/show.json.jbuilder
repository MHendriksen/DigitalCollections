json.merge! @entity.serializable_hash(
  :include => [:medium, :kind, :collection, :datings, :creator, :updater, :authority_groups],
  :methods => [:synonyms, :dataset, :degree, :properties, :display_name],
  :root => false
)

json.fields @entity.kind.field_instances(@entity).map{|f| f.serializable_hash}
json.tags @entity.tag_list.join(', ')
json.generators @entity.kind.generators.map{|g| g.serializable_hash}
      
# json.related blaze.relations_for(@entity, :include_relationships => true)
# json.related_media blaze.relations_for(@entity, :media => true, :include_relationships => true)

json.relation_counts @entity.relation_counts(current_user)
json.media_relation_counts @entity.relation_counts(current_user, media: true)
