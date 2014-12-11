require 'spec_helper'

describe ConfigController do
  include DataHelper

  before :each do
    test_data_for_auth
    
    allow(Kor).to receive(:app_config_file).and_return('config/kor.app.test.yml')
    file = "#{Rails.root}/config/#{Kor.app_config_file}"
    FileUtils.rm file if File.exists? file
  
    session[:user_id] = User.admin.id
    session[:expires_at] = Kor.session_expiry_time
  end
  
  it "should save the config to #{Kor.app_config_file}" do
    post :save_general, :config => {
      'maintainer' => {'name' => 'John Doe'}
    }
    
    expect(Kor::Config.new(Kor.app_config_file)['maintainer.name']).to eql('John Doe')
  end
  
  it "should reload the config after saving" do
    post :save_general, :config => {
      'maintainer' => {'name' => 'John Doe'}
    }
    
    expect(Kor.config['maintainer.name']).to eql('John Doe')
  end
  
  it "should only overwrite updated values in config/kor.app.yml" do
    Kor::Config.new(
      'test' => 'value',
      'maintainer' => {'name' => 'James Kirk'}
    ).store(Kor.app_config_file)
    
    post :save_general, :config => {
      'maintainer' => {'name' => 'John Doe'}
    }
    
    expect(Kor.config['maintainer.name']).to eql('John Doe')
    expect(Kor.config['test']).to eql('value')
  end
  
end
