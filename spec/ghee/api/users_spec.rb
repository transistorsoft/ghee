require 'spec_helper'

describe Ghee::API::Users do
  subject { Ghee.new(GH_AUTH) }

  describe "#user" do
    it "should return authenticated user" do
      VCR.use_cassette('user') do
        user = subject.user
        user['type'].should == 'User'
        user['email'].should_not be_nil
        user['created_at'].should_not be_nil
        user['html_url'].should include('https://github.com/')
        user['name'].should be_instance_of(String)
        user['login'].size.should > 0
      end
    end

    # not sure how to write this test so that it doesn't mess
    # up users info, so I'm just going to take the bio and add
    # a space to the end of it
    describe "#patch" do
      it "should patch the user" do
        VCR.use_cassette('user.patch') do
          before_user = subject.user
          after_user = subject.user.patch({
            :bio => "#{before_user['bio']} "
          })
          after_user['bio'].should == "#{before_user['bio']} "
        end
      end
    end

    # clearly this test is going to fail if the authenticated user isn't part of any organizations
    describe "#orgs" do 
      it "should return list of orgs" do
        VCR.use_cassette "user.orgs" do
          orgs = subject.user.orgs
          orgs.size.should > 0
          orgs.first["url"].should include("https://api.github.com/orgs")
        end
      end
    end

    describe "#repos :type => 'public'" do
      it "should only return public repos" do
        VCR.use_cassette "user.repos.public" do
          repos = subject.user.repos :type => "public"
          repos.size.should > 0
          repos.path_prefix.should == "/user/repos"
          repos.should be_instance_of(Array)
          repos.each do |r|
            r["private"].should be_false
          end
        end
      end
    end

    describe "#repos" do
      it "should return list of repos" do
        VCR.use_cassette "user.repos" do
          repos = subject.user.repos
          repos.size.should > 0
        end
      end

      describe "#paginate" do
        it "should limit the count to 10" do
          VCR.use_cassette "user.repos.paginate" do
            repos = subject.user.repos.paginate :page => 1, :per_page => 10
            repos.size.should == 10
            repos.current_page.should == 1
          end
        end
        it "remove" do
          VCR.use_cassette "testing_pagination" do
            repos = subject.user.repos.paginate :page => 1, :per_page => 100

            repos.total.should > 30
            
          end
        end
      end

    end
  end

  describe "#users" do
    it "should return given user" do
      VCR.use_cassette('users') do
        user = subject.users('jonmagic')
        user['type'].should == 'User'
        user['login'].should == 'jonmagic'
      end
    end
  end
end
