contents << <<HEADER
class #{filename.capitalize}TestCase < Math3d::TestCase

        def set_up
                @#{filename.downcase}s = []
                @#{filename.downcase}s.clear
        end

HEADER
"" << <<Stupid
end
Stupid

