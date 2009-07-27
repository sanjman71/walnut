require 'test/test_helper'
require 'test/factories'

class CompanyTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :name
  should_validate_presence_of   :subdomain
  should_have_many              :locations
  should_have_many              :phone_numbers
  should_have_many              :company_tag_groups
  should_have_many              :tag_groups
  should_belong_to              :timezone
  should_belong_to              :chain
  should_have_one               :subscription
  should_have_many              :services
  should_have_many              :products
  should_have_many              :appointments
  should_have_many              :invitations
  should_have_many              :company_providers
  
  context "company locations" do
    setup do
      @us       = Factory(:us)
      @il       = Factory(:il, :country => @us)
      @chicago  = Factory(:chicago, :state => @il)
      
      @canada   = Factory(:canada)
      @ontario  = Factory(:ontario, :country => @canada)
      @toronto  = Factory(:toronto, :state => @ontario)
      
      @company  = Company.create(:name => "Walnut Industries", :time_zone => "UTC")
      @location = Location.create(:city => @chicago, :country => @us)
      @company.locations.push(@location)
      @company.reload
    end
    
    should_change "Company.count", :by => 1
    should_change "Location.count", :by => 1
    
    should "have 1 location" do
      assert_equal [@location], @company.locations
    end
    
    should "have locations_count of 1" do
      assert_equal 1, @company.locations_count
    end
    
    should "not belong to chain" do
      assert_equal false, @company.chain?
    end
    
    context "then remove location" do
      setup do
        @company.locations.delete(@location)
        @company.reload
      end
      
      should_not_change "Company.count"
      should_not_change "Location.count"

      should "have no locations" do
        assert_equal [], @company.locations
      end

      should "have locations_count of 0" do
        assert_equal 0, @company.locations_count
      end
    end
    
    context "then add a location" do
      setup do
        @location2  = Location.create(:city => @toronto, :country => @us)
        @company.locations.push(@location2)
        @company.reload
      end
    
      should_not_change "Company.count"
      should_change "Location.count", :by => 1
    
      should "have 2 locations" do
        assert_equal [@location, @location2], @company.locations
      end

      should "have locations_count of 2" do
        assert_equal 2, @company.locations_count
      end
    end
  end
  
  context "company phone number" do
    setup do
      @company  = Company.create(:name => "Company 1", :time_zone => "UTC")
      @company.phone_numbers.push(PhoneNumber.new(:name => "Home", :number => "9991234567"))
      @company.reload
    end
  
    should_change "Company.count", :by => 1
    should_change "PhoneNumber.count", :by => 1
    
    should "have 1 phone number" do
      assert_equal ["9991234567"], @company.phone_numbers.collect(&:number)
    end
    
    should "have phone_numbers_count == 1" do
      assert_equal 1, @company.phone_numbers_count
    end

    should "have a primary phone number" do
      assert_equal "9991234567", @company.primary_phone_number.number
    end
  end
  
  context "company tags" do
    setup do
      @company = Company.create(:name => "Company 1", :time_zone => "UTC")
      @company.tag_list.add(["pizza","soccer"])
      @company.save
      @company.reload
    end
    
    should_change "Company.count", :by => 1
    should_change "Tag.count", :by => 2
    should_change "Tagging.count", :by => 2
    
    should "increment tag.taggings count to 1" do
      assert_equal 1, Tag.find_by_name("pizza").taggings.count
      assert_equal 1, Tag.find_by_name("soccer").taggings.count
    end

    should "increment tag.taggings_count to 1" do
      assert_equal 1, Tag.find_by_name("pizza").taggings_count
      assert_equal 1, Tag.find_by_name("soccer").taggings_count
    end
    
    should "increment place.taggings_count to 2" do
      assert_equal 2, @company.taggings_count
    end

    context "then remove a tag" do
      setup do
        @company.tag_list.remove("pizza")
        @company.save
        @company.reload
      end

      should_change "Tagging.count", :by => -1
      
      should "decrement tag.taggings count to 0" do
        assert_equal 0, Tag.find_by_name("pizza").taggings.count
      end

      should "decrement tag.taggings_count to 0" do
        assert_equal 0, Tag.find_by_name("pizza").taggings_count
      end

      should "decrement place.taggings_count to 1" do
        assert_equal 1, @company.taggings_count
      end
    end
    
    context "then add another tag" do
      setup do
        @company.tag_list.add("beer")
        @company.save
        @company.reload 
      end

      should_change "Tag.count", :by => 1
      should_change "Tagging.count", :by => 1

      should "set tag.taggings_count to 1" do
        assert_equal 1, Tag.find_by_name("beer").taggings.count
      end

      should "increment place.taggings_count to 3" do
        assert_equal 3, @company.taggings_count
      end
    end
  end

  context "company subdomain" do
    setup do
      @company = Company.create(:name => "mary's-hair Salon", :time_zone => "UTC")
    end

    should "set and format subdomain" do
      assert_equal "maryshairsalon", @company.subdomain
    end
    
  end
  
  context "company name" do
    setup do
      @company = Company.create(:name => "mary's-hair Salon", :time_zone => "UTC")
    end
    
    should "titleize and format name" do
      assert_equal "Mary's Hair Salon", @company.name
    end
  end
  
  context "company services" do
    setup do
      @company = Company.create(:name => "mary's-hair Salon", :time_zone => "UTC")
    end

    should "have 0 services" do
      assert_equal 0, @company.services_count
    end
  
    should "have 0 work services" do
      assert_equal 0, @company.work_services_count
    end

    context "then add a company service" do
      setup do
        # add the service using the push syntax to ensure the callbacks are used
        @haircut = Factory(:work_service, :name => "Haircut", :price => 10.00)
        assert_valid @haircut
        @company.services.push(@haircut)
        @company.reload
      end

      should "have services_count == 1" do
        assert_equal 1, @company.services_count
      end

      should "have work_services_count == 1" do
        assert_equal 1, @company.work_services_count
      end

      context "then remove the company service" do
        setup do
          @company.services.delete(@haircut)
          @company.reload
        end

        should "have services_count == 0" do
          assert_equal 0, @company.services_count
        end
        
        should "have work_services_count == 0" do
          assert_equal 0, @company.work_services_count
        end
      end
    end
  end
  
  context "company providers" do
    setup do
      @company = Company.create(:name => "mary's-hair Salon", :time_zone => "UTC")
      @user1   = Factory(:user, :name => "User Provider")
      assert_valid @user1
      @company.providers.push(@user1)
      @company.reload
    end
  
    should "have company providers == [@user1]" do
      assert_equal [@user1], @company.providers
    end
    
    should "increment providers_count to 1" do
      assert_equal 1, @company.providers_count
    end

    should "have company.has_provider?(user) return true" do
      assert @company.has_provider?(@user1)
    end

    should "assign role 'provider' to user" do
      assert_equal ['provider'], @user1.roles.collect(&:name)
    end
    
    context "and then remove the user provider" do
      setup do
        @company.providers.delete(@user1)
        @company.reload
      end

      should "have no company providers" do
        assert_equal [], @company.providers
      end

      should "decrement providers_count to 0" do
        assert_equal 0, @company.providers_count
      end

      should "have company.has_provider?(user) return false" do
        assert !@company.has_provider?(@user1)
      end

      should "remove role 'provider' from user" do
        assert_equal [], @user1.roles.collect(&:name)
      end
    end
  end

  context "company subscriptions" do
    setup do
      @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
      @company      = Company.create(:name => "mary's-hair Salon", :time_zone => "UTC", :subscription => @subscription)
    end

    should "have free service" do
      assert @company.free_service
    end
    
    should "have services_count == 1" do
      assert_equal 1, @company.reload.services_count
    end

    should "have work_services_count == 0" do
      assert_equal 0, @company.work_services_count
    end
  end
end