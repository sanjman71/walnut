class Migrate
  
  # copy user.email and user.phone to email_addresses and phone_numbers table
  def self.user_addresses
    migrated = 0

    # find users with emails
    User.all(:conditions => ["email is NOT NULL"]).each do |user|
      email_address = user.email_addresses.create(:address => user.email)
      migrated += 1 if email_address.valid?
    end

    # find usrs with phones
    User.all(:conditions => ["phone is NOT NULL"]).each do |user|
      phone_number = user.phone_numbers.create(:name => 'Mobile', :address => user.phone)
      migrated += 1 if phone_number.valid?
    end

    # set phone_numbers_count
    User.all.each do |user|
      next if user.phone_numbers.size == user.phone_numbers_count
      user.update_attribute(:phone_numbers_count, user.phone_numbers.size)
    end
    
    migrated
  end

end