task :install_scripts do
  to = "#{ENV['HOME']}/bin"
  ( Dir["win*"] + Dir['ruwin.rb'] ).each do |d|
    topath = "#{to}/#{File.basename(d)}"
    frompath = "#{Dir.pwd}/#{d}"

    system "ln -sf #{frompath} #{topath}"
    system "chmod 755 #{topath}"
  end
end
