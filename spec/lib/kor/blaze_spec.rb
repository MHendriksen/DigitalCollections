require 'spec_helper'

describe Kor::Blaze do

  it "should gather relationships in both directions" do
    k = FactoryGirl.create :works
    r = FactoryGirl.create :is_part_of

    g = Credential.create :name => "admins"
    u = FactoryGirl.create :admin
    u.groups << g

    a = FactoryGirl.create :mona_lisa, :kind => k
    b = FactoryGirl.create :der_schrei, :kind => k
    c = FactoryGirl.create :ramirez, :kind => k

    Collection.first.grant :view, :to => g

    Relationship.relate_and_save a, r.name, b
    Relationship.relate_and_save b, r.name, c

    Relationship.count.should == 2

    blaze = Kor::Blaze.new(u, b)
    result = blaze.relations_for(:include_relationships => true)

    result.count.should == 2
    result.first[:relationships].count.should == 1
    result.last[:relationships].count.should == 1
  end

  it "should gather symmetric relationships just once in both directions" do
    k = FactoryGirl.create :works
    r1 = FactoryGirl.create :relation
    r2 = FactoryGirl.create :relation

    g = Credential.create :name => "admins"
    u = FactoryGirl.create :admin
    u.groups << g

    a = FactoryGirl.create :mona_lisa, :kind => k
    b = FactoryGirl.create :der_schrei, :kind => k
    c = FactoryGirl.create :ramirez, :kind => k

    Collection.first.grant :view, :to => g

    Relationship.relate_and_save a, r1.name, b
    Relationship.relate_and_save b, r1.name, c
    Relationship.count.should == 2
    blaze = Kor::Blaze.new(u, b)
    result = blaze.relations_for(:include_relationships => true)
    result.count.should == 1
    result.first[:relationships].count.should == 2
    result.first[:relationships][0][:entity_id].should == a.id
    result.first[:relationships][1][:entity_id].should == c.id

    Relationship.destroy_all
    Relationship.count.should == 0

    Relationship.relate_and_save a, r1.name, b
    Relationship.relate_and_save b, r1.name, c
    Relationship.relate_and_save a, r2.name, b
    Relationship.relate_and_save b, r2.name, c
    Relationship.count.should == 4
    blaze = Kor::Blaze.new(u, b)
    result = blaze.relations_for(:include_relationships => true)
    result.count.should == 1
    result.first[:relationships].count.should == 4
    result.first[:relationships][0][:entity_id].should == a.id
    result.first[:relationships][1][:entity_id].should == a.id
    result.first[:relationships][2][:entity_id].should == c.id
    result.first[:relationships][3][:entity_id].should == c.id
  end

end