# Rewrite the time series input file for Perim to add uncertainty cols
File.open("d:\\perimeta\\misc\\timeseries-in2.csv", "w") do |writefile|

  File.open("d:\\perimeta\\misc\\timeseries-in.csv", "r") do |file|

    file.each do |line|
      cols = line.strip.split(',')
      writefile.write(cols[0])
      cols[1..-1].each do |val|
        writefile.write(',')
        writefile.write(val + ',0.0')
      end
      writefile.write("\n")
    end
  end
end
