class Logo < ActiveRecord::Base
  has_attached_file :image,
                    :styles => { :original => "800x800", :large => "100x200", :medium => "50x100", :small => "25x50" },
                    :default_style => :large

  belongs_to :company

  # We shouldn't have a logo without an attached image
  validates_attachment_presence :image
  validates_attachment_content_type :image, :content_type => [
      'image/jpeg',
      'image/pjpeg', # for progressive Jpeg ( IE mine-type for regular Jpeg ) 
      'image/png',
      'image/x-png', # IE mine-type for PNG
      'image/gif'
    ]
  
  validates_attachment_size :image, :less_than => 1024 * 1024, :message => "The uploaded image is too large. Please make the image less than 1MB"

end
