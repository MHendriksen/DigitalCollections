class WebServices::GoogleMapsLink < WebServices::Link

  def self.label
    "Google Maps"
  end
  
  def self.external_reference_label
    "Adresse"
  end

  def self.link_for(entity)
    id = entity.external_references[name]
    unless id.blank?
      return "http://maps.google.com?q=" + URI.encode(id)
    else
      return nil
    end
  end
  
  def self.needs_external_reference?
    true
  end
  
end
