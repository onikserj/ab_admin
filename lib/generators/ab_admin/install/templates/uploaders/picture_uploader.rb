# -*- encoding : utf-8 -*-
class PictureUploader < AbAdmin::CarrierWave::BaseUploader
  
  process :quality => 90
  
  version :thumb do
    process :resize_to_fill => [80, 80]
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end
end