File.open(ARGV.first){|f|
  deficit=0
  while buf=f.read(1024+deficit)
    #trim possibly incomplete sequences from end
    if /\\[0-7]{0,2}\Z/===buf
      deficit=$&.size
      buf[-deficit..-1]=''
      f.pos-=deficit
    else 
      deficit=0
    end

    $stdout.write buf.gsub(/\\([0-7]{1,3})/){
      $1.oct.&(0xFF).chr 
    }
  end
}
