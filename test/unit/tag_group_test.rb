require 'test/test_helper'
require 'test/factories'

class TagGroupTest < ActiveSupport::TestCase
  
  should_validate_presence_of :name
  should_have_many            :company_tag_groups
  should_have_many            :companies
  
  context "tag group" do
    context "with lowercase name" do
      setup do
        @tagg = TagGroup.create(:name => "fashion")
      end

      should_change("TagGroup.count") { TagGroup.count }
    
      should "have name Fashion" do
        assert_equal 'Fashion', @tagg.name
      end
      
      should "not allow another tag group with the same name" do
        @tagg2 = TagGroup.create(:name => "Fashion")
        assert !@tagg2.valid?
      end
    end

    context "with mixed case name containing dashes" do
      setup do
        @tagg = TagGroup.create(:name => "LAW - criminal")
      end

      should_change("TagGroup.count") { TagGroup.count }

      should "have name Law - Criminal" do
        assert_equal 'Law - Criminal', @tagg.name
      end
    end

    context "with name containing 'and'" do
      setup do
        @tagg = TagGroup.create(:name => "Pizza and beer")
      end
      
      should_change("TagGroup.count") { TagGroup.count }

      should "have name Pizza and Beer" do
        assert_equal 'Pizza and Beer', @tagg.name
      end
    end
    
    context "with no tags" do
      setup do
        @tagg = TagGroup.create(:name => "fashion")
      end

      should_change("TagGroup.count") { TagGroup.count }

      should "have no tags" do
        assert_equal [], @tagg.tag_list
        assert_equal nil, @tagg.tags
      end
    end
    
    context "with non-lowercase tags" do
      setup do
        @tagg = TagGroup.create(:name => "fashion", :tags => ["JEANS", "Diesel"])
      end

      should_change("TagGroup.count") { TagGroup.count }
    
      should "have lowercase tag list" do
        assert_equal ["diesel", "jeans"], @tagg.tag_list
      end
    end
  end

  context "tag group with tags more than 3 words" do
    setup do
      @tagg = TagGroup.create(:name => "fashion", :tags => "jeans, tag is too long")
    end

    should_change("TagGroup.count") { TagGroup.count }
    
    should "have tag list ['jeans']" do
      assert_equal ['jeans'], @tagg.tag_list
      assert_equal "jeans", @tagg.tags
    end
  end
  
  context "tag group with tags" do
    setup do
      @tagg = TagGroup.create(:name => "fashion", :tags => "jeans, diesel")
    end

    should_change("TagGroup.count") { TagGroup.count }
    
    should "have tag list ['diesel', 'jeans']" do
      assert_equal ['diesel', 'jeans'], @tagg.tag_list
      assert_equal "diesel,jeans", @tagg.tags
    end
    
    should "have no recent add or remove tags" do
      assert_equal [], @tagg.recent_add_tag_list
      assert_equal [], @tagg.recent_remove_tag_list
    end
    
    context "then add tags" do
      setup do
        @tagg.add_tags("zathan, zaf")
        @tagg.save
        @tagg.reload
      end
      
      should "have new tags" do
        assert_equal ['diesel', 'jeans', 'zaf', 'zathan'], @tagg.tag_list
      end
      
      should "have recent add tag list == 'zaf,zathan'" do
        assert_equal ['zaf', 'zathan'], @tagg.recent_add_tag_list
      end
      
      context "then remove tags" do
        setup do
          @tagg.remove_tags("zaf, jeans")
          @tagg.save
          @tagg.reload
        end

        should "not have removed tags" do
          assert_equal ['diesel', 'zathan'], @tagg.tag_list
        end
        
        should "have recent removed tag list == 'zaf,zathan'" do
          assert_equal ['jeans', 'zaf'], @tagg.recent_remove_tag_list
        end
      end
    end
    
    context "then add and remove tags at the same time" do
      setup do
        @tagg.add_tags("zathan, zaf")
        @tagg.remove_tags("jeans")
        @tagg.save
        @tagg.reload
      end

      should "have new tags and not the removed tags" do
        assert_equal ['diesel', 'zaf', 'zathan'], @tagg.tag_list
      end
    end
  end
  
  context "tag group with tags" do
    setup do
      @tagg = TagGroup.create(:name => "fashion", :tags => "jeans, diesel")
    end
    
    context "then add company" do
      setup do
        @company = Factory(:company)
        @tagg.companies.push(@company)
        @tagg.reload
        @company.reload
      end
      
      should_change("CompanyTagGroup.count", :by => 1) { CompanyTagGroup.count }
      
      should "add company tags ['diesel', 'jeans']" do
        assert_equal ["diesel", "jeans"], @company.tag_list
      end
      
      should "increment companies_count to 1" do
        assert_equal 1, @tagg.companies_count
      end
            
      context "then remove company" do
        setup do
          @tagg.companies.delete(@company)
          @tagg.reload
          @company.reload
        end
        
        should_change("CompanyTagGroup.count", :by => -1) { CompanyTagGroup.count }
        
        should "remove company tags" do
          assert_equal [], @company.tag_list
        end
        
        should "decrement companies_count to 0" do
          assert_equal 0, @tagg.companies_count
        end
      end
      
      context "then add a tag to the tag group" do
        setup do
          @tagg.add_tags("zatiny")
          @tagg.save
          @company.reload
        end
        
        should "have the dirty flag set" do
          assert_equal true, @tagg.dirty?
        end
        
        context "and apply tags" do
          setup do
            @tagg.apply
            @tagg.reload
          end

          should "not have the dirty flag set" do
            assert_equal false, @tagg.dirty?
          end

          should "add new tag to company tags" do
            assert_equal ["diesel", "jeans", "zatiny"], @company.tag_list
          end
        end
      end
    end
  end
  
end