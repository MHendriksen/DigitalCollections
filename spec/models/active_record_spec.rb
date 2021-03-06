require 'rails_helper'

describe ActiveRecord do
  include DataHelper

  it "should find or initialize with additional attributes" do
    u = User.find_or_initialize_by(:name => "Gagamel")
    u.attributes = { :email => "gagamel@schloss.com" }
    u.save
    gagamel = User.find_by_name("Gagamel")
    
    expect(gagamel.email).to eql("gagamel@schloss.com")
  end
  
  it "should take custom values for the timestamps" do
    timestamp = Time.now - 2.weeks
    u = User.create(:name => "Gagamel", :email => "gagamel@schloss.com", :updated_at => timestamp)
    expect(User.find_by_name("Gagamel").updated_at).to be_within(5.seconds).of(timestamp)
  end
  
  it "does insert duplicate links for many-to-many associations" do
    test_data_for_auth
    test_kinds
    test_entities
    test_authority_groups
    
    group = AuthorityGroup.first
    
    group.entities << Entity.first
    group.entities << Entity.first
    
    expect(group.entities.count).to eql(2)
  end
end
