require 'rails_helper'

describe Medium do

  it "should not accept non-image-files as image attachment" do
    expect(Medium.new(:image => File.open("#{Rails.root}/spec/fixtures/text_file.txt")).valid?).to be_falsey
  end
  
  it "should accept images as image attachment" do
    medium = Medium.new(:image => File.open("#{Rails.root}/spec/fixtures/image_a.jpg"))
    expect(medium).to be_valid
  end
  
  it "should return correct paths and urls" do
    Delayed::Worker.delay_jobs = false

    medium = Medium.create :document => File.open("#{Rails.root}/spec/fixtures/text_file.txt")
    medium.reload

    expect(medium.path(:original)).to eql("#{Rails.root}/data/media.test/original/#{medium.ids}/document.txt")
    expect(medium.path(:icon)).to eql("#{Rails.root}/public/content_types/text.gif")
    expect(medium.url(:original)).to eql("/media/images/original/#{medium.ids}/document.txt?#{medium.document.updated_at}")
    expect(medium.url(:icon)).to eql('/content_types/text.gif')
    
    medium.update_attributes(:image => File.open("#{Rails.root}/spec/fixtures/image_a.jpg"))
    medium.reload
    
    expect(medium.path(:original)).to eql("#{Rails.root}/data/media.test/original/#{medium.ids}/document.txt")
    expect(medium.path(:icon)).to eql("#{Rails.root}/data/media.test/icon/#{medium.ids}/image.jpg")
    expect(medium.url(:original)).to eql("/media/images/original/#{medium.ids}/document.txt?#{medium.document.updated_at}")
    expect(medium.url(:icon)).to eql("/media/images/icon/#{medium.ids}/image.jpg?#{medium.image.updated_at}")
    
    medium.update_attributes(:document => nil)
    medium.reload
    
    expect(medium.path(:original)).to eql("#{Rails.root}/data/media.test/original/#{medium.ids}/image.jpg")
    expect(medium.path(:icon)).to eql("#{Rails.root}/data/media.test/icon/#{medium.ids}/image.jpg")
    expect(medium.url(:original)).to eql("/media/images/original/#{medium.ids}/image.jpg?#{medium.image.updated_at}")
    expect(medium.url(:icon)).to eql("/media/images/icon/#{medium.ids}/image.jpg?#{medium.image.updated_at}")
  end
  
  it "should read an escaped file uri to an existing file" do
    Delayed::Worker.delay_jobs = false

    medium = Medium.create :uri => "file:///#{Rails.root}/spec/fixtures/image_a.jpg"
    medium = Medium.last
    
    expect(medium.document.file?).to be_falsey
    expect(medium.to_file :image).not_to be_nil
    expect(medium.image.content_type).to eql('image/jpeg')
  end
  
  it "should not store the same file twice (hashing-check)" do
    Medium.create :document => File.open("#{Rails.root}/spec/fixtures/text_file.txt")
    medium = Medium.new :document => File.open("#{Rails.root}/spec/fixtures/text_file.txt")
    
    expect(medium.save).to be_falsey
    expect(medium.errors.full_messages).to eql(
      ['data hash a file with identical content already exists']
    )
  end
  
  it "should return the dummy when no files are attached" do
    medium = Medium.new
    expect(medium.save).to be_falsey
    expect(medium.errors[:document]).to eq(
      ['please select a file']
    )
  end
  
  it "should delete all files after destruction of an image" do
    Delayed::Worker.delay_jobs = false

    medium = Medium.create :document => File.open("#{Rails.root}/spec/fixtures/image_a.jpg")
    medium = Medium.last
    
    paths = [:original, :icon, :thumbnail, :preview, :normal].map{|s| medium.path(s)}
    
    paths.each do |path|
      expect(File.exists?(path)).to be_truthy
    end
    
    medium.destroy
    
    paths.each do |path|
      expect(File.exists?(path)).to be_falsey
    end
  end
  
  it "should not generate the checksum error twice" do
    original = FactoryGirl.create(:medium_image_a)
    duplicate = FactoryGirl.build(:medium_image_a)
    
    expect(duplicate.valid?).not_to be_truthy
    expect(duplicate.errors.full_messages).to eq(
      ["data hash a file with identical content already exists"]
    )
  end
  
  it "should generate a delayed job for processing" do
    Delayed::Worker.delay_jobs = true
    expect(Delayed::Job.count).to eq(0)
    medium = FactoryGirl.create(:medium_image_a)
    expect(Delayed::Job.count).to eq(2)
  end

  it "should generate a datahash for attachments" do
    medium = FactoryGirl.create :medium_image_a
    medium = Medium.last
    expect(medium.datahash).to eq("233fcdfee7c55b3978967aacaefb9a08057607a0")
  end

  context 'content types' do

    before :all do
      Dir["#{Rails.root}/lib/paperclip_processors/*"].each{|f| require f}
    end

    before :each do
      Delayed::Worker.delay_jobs = false
      FactoryGirl.create :media
    end

    it "should determine the processors according to the document content type" do
      medium = Medium.new
      expect(medium).to receive(:processors).and_call_original
      expect(medium.processors).to eq([])

      medium = FactoryGirl.build(:picture_a).medium
      expect(medium.processors).to eq([])

      medium = FactoryGirl.build(:video_a).medium
      expect(medium.processors).to eq([:video])

      medium = FactoryGirl.build(:video_b).medium
      expect(medium.processors).to eq([:video])

      medium = FactoryGirl.build(:audio_a).medium
      expect(medium.processors).to eq([:audio])

      medium = FactoryGirl.build(:audio_b).medium
      expect(medium.processors).to eq([:audio])
    end

    it "should not run the video processor for images" do
      expect(Paperclip::Video).not_to receive(:make)
      expect(Paperclip::Audio).not_to receive(:make)
      medium = FactoryGirl.create :picture_a
    end

    it "should run the video processor for videos" do
      expect(Paperclip::Video).to receive(:make).at_least(:once).and_call_original
      expect(Paperclip::Audio).not_to receive(:make)
      medium = FactoryGirl.create :video_a
    end

    it "should run the audio processor for audio" do
      expect(Paperclip::Video).not_to receive(:make)
      expect(Paperclip::Audio).to receive(:make).at_least(:once).and_call_original
      medium = FactoryGirl.create :audio_a
    end

    it "should convert a video to all 3 major html5 containers/codecs" do
      medium = FactoryGirl.create :video_a
      document = medium.medium.document
      expect(File.size document.path(:mp4)).to be > 0
      expect(File.size document.path(:webm)).to be > 0
      expect(File.size document.path(:ogg)).to be > 0
    end

    it "should convert a audio file to all 2 major html5 containers/formats" do
      medium = FactoryGirl.create :audio_a
      document = medium.medium.document
      expect(File.size document.path(:mp3)).to be > 0
      expect(File.size document.path(:ogg)).to be > 0
    end

    it "should destroy custom styles with the medium" do
      medium = FactoryGirl.create :audio_a
      document = medium.medium.document
      paths = [document.path(:mp3), document.path(:ogg)]

      medium.reload.destroy
      expect(File.exists? paths[0]).to be_falsey
      expect(File.exists? paths[1]).to be_falsey
    end

  end
  
end
