namespace :tmp do
  desc "Clear session, cache, and socket files from tmp/"
  task :clear => [ "tmp:sessions:clear",  "tmp:cache:clear", "tmp:sockets:clear"]

  desc "Creates tmp directories for sessions, cache, and sockets"
  task :create do
    FileUtils.mkdir_p(%w( tmp/sessions tmp/cache tmp/sockets ))
  end

  namespace :sessions do
    desc "Clears all files in tmp/sessions"
    task :clear do
      FileUtils.rm(Dir['tmp/sessions/[^.]*'])
    end
  end

  namespace :cache do
    desc "Clears all files and directories in tmp/cache"
    task :clear do
      FileUtils.rm_rf(Dir['tmp/cache/[^.]*'])
    end
  end

  namespace :sockets do
    desc "Clears all ruby_sess.* files in tmp/sessions"
    task :clear do
      FileUtils.rm(Dir['tmp/sockets/[^.]*'])
    end
  end
end