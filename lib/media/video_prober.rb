class Media::VideoProber
  
  def initialize(file)
    @file = file
  end
  
  def probe
    `ffprobe -show_streams -show_format #{@file} 2> /dev/null`
  end
  
  def streams
    @streams ||= begin
      results = []
    
      current = nil
      
      probe.split("\n").to_a.map{|l| l.strip}.each do |line|
        if line == '[STREAM]' || line == '[FORMAT]'
          current = {}
        elsif line == '[/STREAM]' || line == '[/FORMAT]'
          results << current
        else
          k, v = line.split('=')
          current[k.to_sym] = v
        end
      end
      
      results
    end
  end
  
  def video_stream
    @video_stream ||= if video_streams.size == 0
      raise Media::ProcessorException, "there are no video streams"
    elsif video_streams.size > 1
      #raise "there are more than one video stream"
      video_streams.first
    else
      video_streams.first
    end
  end
  
  def audio_stream
    @audio_stream ||= if audio_streams.size == 0
      nil
    elsif audio_streams.size > 1
#      raise "there are more than one audio stream"
      audio_streams.first
    else
      audio_streams.first
    end
  end
  
  def format
    streams.select{|s| s.keys.include? :filename}.first
  end
  
  def quality
    attributes[:quality]
  end
  
  def width
    attributes[:video][:width]
  end
  
  def height
    attributes[:video][:height]
  end
  
  def suggested_video_bitrate
    [3.0, quality].min * suggested_width * suggested_height
  end
  
  def suggested_width
    [720, width].min.to_i
  end
  
  def suggested_height
    (suggested_width * (1.0 / aspect)).to_i
  end
  
  def aspect
    width.to_f / height
  end
  
  def attributes
    @attributes ||= begin
      result = {
        :video => {
          :codec => video_stream[:codec_name],
          :format => video_stream[:pix_fmt],
          :width => video_stream[:width].to_i,
          :height => video_stream[:height].to_i
        },
        :bitrate => format[:bit_rate].to_i,
        :size => format[:size].to_i,
        :duration => format[:duration].to_i
      }
      
      if audio_stream
        result[:audio] = {
          :codec => audio_stream[:codec_name],
          :channels => audio_stream[:channels].to_i
        }
        
        result[:audio][:bitrate] = result[:audio][:channels] * audio_stream[:sample_rate].to_i * audio_stream[:bits_per_sample].to_i
      else
        result[:audio] = {
          :bitrate => 0
        }
      end
      
      result[:video][:bitrate] = result[:bitrate] - result[:audio][:bitrate]
      result[:quality] = result[:video][:bitrate].to_f / result[:video][:width] / result[:video][:height]
      
      result
    end
  end
  
  def audio_streams
    streams.select{|s| s[:codec_type] == 'audio'}
  end
  
  def video_streams
    streams.select{|s| s[:codec_type] == 'video'}
  end
  
end
