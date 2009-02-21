require 'test/test_helper'
require 'test/factories'

class TagGroupTest < ActiveSupport::TestCase
  
  should_require_attributes   :name
  should_have_many            :place_tag_groups
  should_have_many            :places
  
  context "tag group" do
    context "with no tags" do
      setup do
        @tagg = TagGroup.create(:name => "fashion")
      end

      should_change "TagGroup.count"
    
      should "have no tags" do
        assert_equal [], @tagg.tag_list
        assert_equal nil, @tagg.tags
      end
    end
    
    context "with lowercase name" do
      setup do
        @tagg = TagGroup.create(:name => "fashion")
      end

      should_change "TagGroup.count"
    
      should "have name Fashion" do
        assert_equal 'Fashion', @tagg.name
      end
    end

    context "with non-lowercase tags" do
      setup do
        @tagg = TagGroup.create(:name => "fashion", :tags => ["JEANS", "Diesel"])
      end

      should_change "TagGroup.count"
    
      should "have lowercase tag list" do
        assert_equal ["diesel", "jeans"], @tagg.tag_list
      end
    end
  end

  context "tag group with tags" do
    setup do
      @tagg = TagGroup.create(:name => "fashion", :tags => "jeans, diesel")
    end

    should_change "TagGroup.count"
    
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
    
    context "then add place" do
      setup do
        @place = Place.create(:name => "Place 1")
        @tagg.places.push(@place)
        @tagg.reload
        @place.reload
      end
      
      should_change "PlaceTagGroup.count", :by => 1
      
      should "add place tags ['diesel', 'jeans']" do
        assert_equal ["diesel", "jeans"], @place.tag_list
      end
      
      should "increment places_count to 1" do
        assert_equal 1, @tagg.places_count
      end
            
      context "then remove place" do
        setup do
          @tagg.places.delete(@place)
          @tagg.reload
          @place.reload
        end
        
        should_change "PlaceTagGroup.count", :by => -1
        
        should "remove place tags" do
          assert_equal [], @place.tag_list
        end
        
        should "decrement places_count to 0" do
          assert_equal 0, @tagg.places_count
        end
      end
      
      context "then add tag to tag group" do
        setup do
          @tagg.add_tags("zatiny")
          @tagg.save
          @tagg.apply
          @place.reload
        end
        
        should "add new tag to all tag group places" do
          assert_equal ["diesel", "jeans", "zatiny"], @place.tag_list
        end
      end
    end
  end
  
end