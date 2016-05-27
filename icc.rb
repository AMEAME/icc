require 'optparse'

def cmdline
  args = { include_dir: '', output: false }
  OptionParser.new do |opt|
    opt.on('-I [VALUE]') { |v| args[:include_dir] = v if v }
    opt.on('-o') { args[:output] = true }
    opt.parse!(ARGV)
  end
  args
end

args = cmdline
headers = Dir.foreach('./' + args[:include_dir]).select { |f| f[-2, 2] == '.h' }
headers = []
headers.each do |h|
  exit unless system('gcc -c ' + h.tr('.h', '.c') \
    + ' -o ' + h.tr('.h', '.o'))
end

header = "#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n" \
  + headers.reduce('') { |a, e| a + "#include \"#{e}\"\n" }

line = 0
code = ''
tmp_header = ''
tmp_obj = ''
indent = '    '
has_if = false
buf = ''

loop do
  print "icc(main):#{format('%03d', line)}> "
  input = gets.to_s.chomp
  line += 1
  break if input == 'q' || input == 'exit'

  input = 'printf("%s", ' + input[1..-1] + ')' if input.split(' ').first == 'p'
  input = 'printf("%d", ' + input[2..-1] + ')' if input.split(' ').first == 'pi'



  buf += indent * 2 + input + ";\n" if !input.include?('}') && has_if
  if input.include?('{')
    has_if = true
    buf += input + ";\n"
  end

  if input.include?('}')
    input = buf + indent + input
    buf = ''
    has_if = false
  end

  next if has_if

  if input.split(' ').first == 'include'
    header_name = input[7..-1].tr(' ', '')
    tmp_header = '#include "' + input[7..-1].tr(' ', '') + ".h\"\n"
    tmp_obj = input[7..-1].tr(' ', '') + '.o'
    input = ''
  end
  out = header + tmp_header + "\nint main()\n{\n" \
    + code + indent + input + ";\n" + "\n}"

  out.gsub!(";\n;", ';')
  out.gsub!(';;', ';')
  out.gsub!('};', '}')
  out.gsub!('{;', '{')
  out.gsub!("{\n    ;", '{')
  File.open('tmp.c', 'w') { |f| f.puts out }

  if header_name && header_name != ''
    puts "gcc -c #{header_name}.c -o #{header_name}.o"
    next unless system("gcc -c #{header_name}.c -o #{header_name}.o")
    header << tmp_header + "\n"
  end

  puts 'gcc tmp.c -o tmp.out'
  next unless system('gcc tmp.c -o tmp.out')
  code << '  ' + input + ";\n"

  if RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|cygwin|bccwin/
    puts '=> ' + `tmp.out`
  else
    puts '=> ' + `./tmp.out`
  end

  unless args[:output]
    `rm tmp.c`
    `rm tmp.out`
  end

  next unless code.include?('printf')
  code.slice!(code.index('printf'), code.index(';', code.index('printf')))

end
