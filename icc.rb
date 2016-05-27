pre = <<'EOS'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
EOS

header = []
line = 0
code = ''

loop do
  print "icc(main):#{line}> "
  input = gets.to_s.chomp
  line += 1

  break if input == 'q' || input == 'exit'

  input = 'printf("%s", ' + input[1..-1] + ')' if input.split(' ').first == 'p'
  input = 'printf("%d", ' + input[2..-1] + ')' if input.split(' ').first == 'pi'
  pre_f = pre
  if input.split(' ').first == 'include'
    pre_f << '#include "' + input[7..-1].tr(' ', '') + ".h\"\n"
    header = input[7..-1].tr(' ', '') + '.o'
    input = ''
  end

  out = pre_f + "\nint main()\n{\n" + code + '  ' + input + ";\n" + "\n}"

  out.gsub!(";\n;", ';')
  out.gsub!(';;', ';')

  File.open('tmp.c', 'w') { |f| f.puts out }

  next unless system("gcc #{} -c -o '' ")
  code << '  ' + input + ";\n"

  next unless system('gcc tmp.c -o tmp.out')
  code << '  ' + input + ";\n"

  if RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|cygwin|bccwin/
    puts `tmp.out`
  else
    puts `./tmp.out`
  end
  # `rm tmp.c`
  # `rm tmp.out`


  next unless code.include?('printf')
  code.slice!(code.index('printf'), code.index(';', code.index('printf')))

end
