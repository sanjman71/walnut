require 'test/test_helper'

class MessageTest < ActiveSupport::TestCase

  should_belong_to              :sender
  should_validate_presence_of   :sender_id, :body
  should_have_many              :message_recipients
  should_have_many              :message_topics
  should_have_many              :company_message_deliveries
  should_have_many              :companies
  
  context "create" do
    context "with email nested attributes" do
      setup do
        @recipient  = Factory(:user, :name => "Recipient")
        @email      = @recipient.email_addresses.create(:address => "a@b.com")
        @attrs      = Hash["0" => {:messagable_id => @email.id, :messagable_type => 'EmailAddress', :protocol => 'email'}]
        @sender     = Factory(:user, :name => "Sender") 
        @message    = Message.create(:sender => @sender, :subject => "Message subject", :body => "Message body",
                                     :message_recipients_attributes => @attrs)
      end

      should_change("Message.count", :by => 1) { Message.count }
      should_change("MessageRecipient.count", :by => 1) { MessageRecipient.count }
      
      should "set recipient to email address" do
        assert_equal [@email], @message.message_recipients.collect(&:messagable)
      end
    end

    context "with company message delivery" do
      context "using association create method" do
        setup do
          @company            = Factory(:company, :name => "Company 1")
          @sender             = Factory(:user, :name => "Sender")
          @message            = Message.create(:sender => @sender, :subject => "Message subject", :body => "Message body")
          @recipient          = Factory(:user, :name => "Recipient")
          @message_recipient  = @message.message_recipients.create(:messagable => @recipient, :protocol => "local")
          @message_delivery   = @company.company_message_deliveries.create(:message => @message, :message_recipient => @message_recipient)
        end

        should_change("Message.count", :by => 1) { Message.count }
        should_change("Company.count", :by => 1) { Company.count }
        should_change("CompanyMessageDelivery.count", :by => 1) { CompanyMessageDelivery.count }

        should "change company.messages collection" do
          assert_equal [@message], @company.reload.messages
        end

        should "change message.companies collection" do
          assert_equal [@company], @message.reload.companies
        end

        should "have non-empty named scope for_company collection" do
          assert_equal [@message_delivery], CompanyMessageDelivery.for_company(@company)
        end

        should "have non-empty named scope for_protocol collection" do
          assert_equal [@message_delivery], CompanyMessageDelivery.for_protocol('local')
        end

        should "have non-empty named scope for_company, for_protocol collection" do
          assert_equal [@message_delivery], CompanyMessageDelivery.for_company(@company).for_protocol('local')
        end
      end
      
      context "using add method" do
        setup do
          @company            = Factory(:company, :name => "Company 1")
          @sender             = Factory(:user, :name => "Sender")
          @message            = Message.create(:sender => @sender, :subject => "Message subject", :body => "Message body")
          @recipient          = Factory(:user, :name => "Recipient")
          @message_recipient  = @message.message_recipients.create(:messagable => @recipient, :protocol => "local")
          # add company customer as a message topic
          @user               = Factory(:user)
          @user.grant_role('company customer', @company)
          @message_topic      = @message.message_topics.create(:topic => @user, :tag => 'test')
          @added_count        = CompanyMessageDelivery.add(@message)
          assert_equal 1, @added_count
        end

        should_change("Message.count", :by => 1) { Message.count }
        should_change("Company.count", :by => 1) { Company.count }
        should_change("CompanyMessageDelivery.count", :by => 1) { CompanyMessageDelivery.count }

        should "change company.messages collection" do
          assert_equal [@message], @company.reload.messages
        end

        should "change message.companies collection" do
          assert_equal [@company], @message.reload.companies
        end
      end
    end

    setup do
      @sender   = Factory(:user, :name => "Sender") 
      @message  = Message.create(:sender => @sender, :subject => "Message subject", :body => "Message body")
    end

    should_change("Message.count", :by => 1) { Message.count }

    context "add user message recipient" do
      setup do
        @recipient          = Factory(:user, :name => "Recipient")
        @message_recipient  = @message.message_recipients.create(:messagable => @recipient, :protocol => "local")
      end

      should_change("MessageRecipient.count", :by => 1) { MessageRecipient.count }

      should "start in 'created' state" do
        @message.reload
        assert_equal 'created', @message_recipient.state
      end

      should "change sender's outbox collection" do
        assert_equal [@message], @sender.outbox
        assert_equal [], @sender.inbox
      end

      should "change recipient's inbox collection" do
        assert_equal [@message], @recipient.inbox
        assert_equal [], @recipient.outbox
      end

      context "send message" do
        setup do
          @sent_at = @message_recipient.sent_at
          @message.send!
        end

        should "change recipient state to 'unread'" do
          @message_recipient.reload
          assert_equal 'unread', @message_recipient.state
        end
        
        should "change recipient sent_at timestamp" do
          @message_recipient.reload
          assert_not_equal @sent_at, @message_recipient.sent_at
        end
      end
    end
  
    context "add invitation message recipient" do
      setup do
        @recipient          = Invitation.create(:recipient_email => 'sanjay@jarna.com')
        @message_recipient  = @message.message_recipients.create(:messagable => @recipient, :protocol => @recipient.protocol)
      end

      should_change("MessageRecipient.count", :by => 1) { MessageRecipient.count }

      should "start in 'created' state" do
        @message.reload
        assert_equal 'created', @message_recipient.state
      end

      context "send message" do
        setup do
          @sent_at = @message_recipient.sent_at
          @message.send!
        end

        should_change("delayed job count", :by => 1) { Delayed::Job.count }
      end
    end
  end

  context "delete" do
    setup do
      @sender   = Factory(:user, :name => "Sender") 
      @message  = Message.create(:sender => @sender, :subject => "Message subject", :body => "Message body")
    end

    context "message with 1 recipient" do
      setup do
        @recipient1         = Factory(:user, :name => "Recipient 1")
        @message_recipient1 = @message.message_recipients.create(:messagable => @recipient1, :protocol => "local")
        @message.send!
      end

      should_change("MessageRecipient.count", :by => 1) { MessageRecipient.count }

      should "delete message when recipient is deleted" do
        @message_recipient1.destroy
        assert_equal nil, Message.find_by_id(@message.id)
      end
    end

    context "message with 2 recipients" do
      setup do
        @recipient1         = Factory(:user, :name => "Recipient 1")
        @recipient2         = Factory(:user, :name => "Recipient 2")
        @message_recipient1 = @message.message_recipients.create(:messagable => @recipient1, :protocol => "local")
        @message_recipient2 = @message.message_recipients.create(:messagable => @recipient2, :protocol => "local")
        @message.send!
      end

      should_change("MessageRecipient.count", :by => 2) { MessageRecipient.count }

      should "not delete message when recipient is deleted" do
        @message_recipient1.destroy
        assert_equal @message, Message.find_by_id(@message.id)
      end

      should "not allow message to be deleted" do
        @message.destroy
        assert_equal @message, Message.find_by_id(@message.id)
      end
    end
  end

  context "reply" do
    setup do
      @sender             = Factory(:user, :name => "Sender") 
      @message            = Message.create(:sender => @sender, :subject => "Message subject", :body => "Message body")
      @recipient1         = Factory(:user, :name => "Recipient 1")
      @message_recipient1 = @message.message_recipients.create(:messagable => @recipient1, :protocol => "local")
      @message.send!
    end

    context "to sender" do
      setup do
        @user           = Factory(:user, :name => "User")
        @message_reply  = @message.reply(:sender => @user, :subject => "Reply to your message", :body => "Reply body")
      end

      should_change("Message.count", :by => 1) { Message.count }
      should_change("MessageThread.count", :by => 2) { MessageThread.count }

      should "set reply thread == original message thread" do
        assert_equal @message_reply.message_thread.thread, @message.message_thread.thread
      end

      should "have 2 messages in thread" do
        assert_equal 2, MessageThread.find_all_by_thread(@message.message_thread.thread).size
      end

      context "then send another reply to the same message" do
        setup do
          @message_reply2 = @message.reply(:sender => @user, :subject => "Reply again", :body => "Reply body")
        end

        should_change("Message.count", :by => 1) { Message.count }
        should_change("MessageThread.count", :by => 1) { MessageThread.count }

        should "have 3 messages in thread" do
          assert_equal 3, MessageThread.with_thread(@message.message_thread.thread).count
        end
      end
    end
  end

  context "message topics" do
    setup do
      @sender   = Factory(:user, :name => "Sender") 
      @message  = Message.create(:sender => @sender, :subject => "Message subject", :body => "Message body")
      @user     = Factory(:user)
      @topic1   = @message.message_topics.create(:topic => @user, :tag => 'ping')
    end

    should_change("MessageTopic.count", :by => 1) { MessageTopic.count }

    should "add user topic to message" do
      assert_equal [@user], @message.reload.user_topics
    end

    should "add message to user" do
      assert_equal [@message], @user.reload.messages
    end
  end

end