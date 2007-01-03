require 'mkmf'
require File.dirname(__FILE__) + '/oraconf'

RUBY_OCI8_VERSION = open("#{File.dirname(__FILE__)}/../../VERSION") {|f| f.read}.chomp

oraconf = OraConf.get()

def replace_keyword(source, target, replace)
  puts "creating #{target} from #{source}"
  open(source, "rb") { |f|
    buf = f.read
    replace.each do |key, value|
      buf.gsub!('@@' + key + '@@', value)
    end
    open(target, "wb") {|fw|
      fw.write buf
    }
  }        
end

$objs = ["oci8.o", "handle.o", "const.o", "env.o", "error.o", "svcctx.o",
         "server.o", "session.o", "stmt.o", "define.o", "bind.o",
         "describe.o", "descriptor.o", "param.o", "lob.o",
         "oradate.o", "oranumber.o", "ocinumber.o", "attr.o"]

$CFLAGS += oraconf.cflags
$libs += oraconf.libs

# OCIEnvCreate
#   8.0.5  - NG
#   9.0.1  - OK
have_func("OCIEnvCreate")

# OCITerminate
#   8.0.5  - NG
#   9.0.1  - OK
have_func("OCITerminate")

# OCIServerRelease
#   8.1.5  - NG
#   8.1.7  - OK
#have_func("OCIServerRelease")

# OCILobOpen
#   8.0.5  - NG
#   9.0.1  - OK
have_func("OCILobOpen")

# OCILobClose
#   8.0.5  - NG
#   9.0.1  - OK
have_func("OCILobClose")

have_func("OCILobGetChunkSize")
have_func("OCILobLocatorAssign")

$defs.push("-DHAVE_OCIRESET") unless /80./ =~ oraconf.version

# Checking gcc or not
if oraconf.cc_is_gcc
  $CFLAGS += " -Wall"
end

# replace files
replace = {
  'OCI8_CLIENT_VERSION' => oraconf.version,
  'OCI8_MODULE_VERSION' => RUBY_OCI8_VERSION
}

# make ruby script before running create_makefile.
replace_keyword(File.dirname(__FILE__) + '/../../lib/oci8.rb.in', '../../lib/oci8.rb', replace)

create_header()
$defs = []

# make dependency file
open("depend", "w") do |f|
  f.puts("Makefile: extconf.rb oraconf.rb")
  f.puts("\t$(RUBY) extconf.rb")
  $objs.each do |obj|
    f.puts("#{obj}: $(srcdir)/#{obj.sub(/\.o$/, ".c")} $(srcdir)/oci8.h Makefile")
  end
end


create_makefile("oci8lib")

# append version info to extconf.h
open("extconf.h", "a") do |f|
  replace.each do |key, value|
    f.puts("#define #{key} \"#{value}\"")
  end
end

exit 0
