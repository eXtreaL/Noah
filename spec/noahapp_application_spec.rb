require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Using the Application API", :reset_redis => false do
  before(:all) do
    @a = Noah::Application.create(:name => 'rspec_sample_app')
    @c = Noah::Configuration.create(:name => 'rspec_config', :format => 'string', :body => 'rspec is great')
    @a.configurations << @c
    @a.save
  end  
  describe "calling" do

    describe "GET" do
      it "all applications should work" do
        get '/applications'
        last_response.should be_ok
        response = last_response.should return_json
        response.is_a?(Hash).should == true
      end
      it "named application should work" do
        get '/applications/rspec_sample_app'
        last_response.should be_ok
        response = last_response.should return_json
        response.has_key?(@a.name).should == true
        response[@a.name].class.to_s.should == 'Hash'
        response[@a.name]["id"].should == @a.id.to_s
        response[@a.name].has_key?("configurations").should == true
        c = response[@a.name]["configurations"]
        c.has_key?(@c.name).should == true
        c["#{@c.name}"]["format"].should == "#{@c.format}"
        c["#{@c.name}"]["body"].should == "#{@c.body}"
      end
      it "named configuration for application should work" do
        get "/applications/#{@a.name}/#{@c.name}"
        last_response.should be_ok
        response = last_response.should return_json

        response["id"].should == @c.id
        response["name"].should == @c.name
        response["format"].should == @c.format
        response["body"].should == @c.body
      end
      it "invalid application should not work" do
        get "/applications/should_not_exist"
        last_response.should be_missing
      end  
      it "invalid configuration for application should not work" do
        get "/applications/should_not_exist/should_not_exist"
        last_response.should be_missing
      end
    end

    describe "PUT" do
      before(:all) do
        @appdata = {:name => "should_now_exist"}
      end  
      it "new application should work" do
        put "/applications/#{@appdata[:name]}", @appdata.to_json, "CONTENT_TYPE" => "application/json"
        last_response.should be_ok
        response = last_response.should return_json
        response["result"].should == "success"
        response["id"].nil?.should == false
        response["name"].should == @appdata[:name]
        response["action"].should == "create"
        Noah::Application.find(:name => @appdata[:name]).size.should == 1
        Noah::Application.find(:name => @appdata[:name]).first.is_new?.should == true
      end
      it "new application with missing name should not work" do
        put "/applications/should_not_work", '{"foo":"bar"}', "CONTENT_TYPE" => "application/json"
        last_response.should be_invalid
      end
      it "existing application should work" do
        sleep 3

        put "/applications/#{@appdata[:name]}", @appdata.to_json, "CONTENT_TYPE" => "application/json"
        last_response.should be_ok
        response = last_response.should return_json
        response["result"].should == "success"
        response["id"].nil?.should == false
        response["name"].should == @appdata[:name]
        response["action"].should == "update"
        Noah::Application.find(:name => @appdata[:name]).size.should == 1
        Noah::Application.find(:name => @appdata[:name]).first.is_new?.should == false
      end  
    end

    describe "DELETE" do
      before(:each) do
        @appdata = {:name => "should_now_exist"}
      end  
      it "existing application should work" do
        delete "/applications/#{@appdata[:name]}"
        last_response.should be_ok
        response = last_response.should return_json
        response["result"].should == "success"
        response["action"].should == "delete"
        response["id"].nil?.should == false
        response["name"].should == @appdata[:name]
      end
      it "invalid application should not work" do
        delete "/applications/should_not_work"
        last_response.should be_missing
      end
    end

  end
end  
