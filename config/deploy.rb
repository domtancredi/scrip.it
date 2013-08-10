################################################################################
# Capistrano recipe for deploying ExpressionEngine websites from GitHub        #
# By Dan Benjamin - http://doodaastudio.com/                                   #
################################################################################


##### Settings #####

# the name of your website - should also be the name of the directory
set :application, "scripty.domandtom.com"
#set :application, "23.21.183.131"

# the name of your system directory, which you may have customized
set :system, "system/cms"

# the path to your new deployment directory on the server
# by default, the name of the application (e.g. "/var/www/sites/example.com")
set :deploy_to, "/var/www/scripty"

# the git-clone url for your repository
set :repository, "git@github.com:domtancredi/scrip.it.git"

# the branch you want to clone (default is master)
set :branch, "2.2/master"

# the name of the deployment user-account on the server
set :user, "ubuntu"

##### You shouldn't need to edit below unless you're customizing #####

# Additional SCM settings
set :scm, :git
set :ssh_options, { :forward_agent => true, :keys => [File.join(ENV["HOME"], ".ssh", "scripty.pem")] }
set :deploy_via, :remote_cache
set :copy_strategy, :checkout
set :keep_releases, 3
set :scm_verbose, true
set :use_sudo, true
set :copy_compression, :bz2

# Roles
role :app, "#{application}"
role :web, "#{application}"
role :db,  "#{application}", :primary => true

# Deployment process
after "deploy:update", "deploy:cleanup" 
after "deploy", "deploy:set_permissions", "deploy:create_symlinks", "deploy:set_content_permissions"

# Custom deployment tasks
namespace :deploy do

  desc "This is here to override the original :restart"
  task :restart, :roles => :app do
    # do nothing but overide the default
  end

  task :finalize_update, :roles => :app do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
    # overide the rest of the default method
  end

  desc "Create additional directories and set permissions after initial setup"
  task :after_setup, :roles => :app do
    # create upload directories
    run "mkdir -p #{deploy_to}/#{shared_dir}/assets"
    # set permissions
    run "chmod 777 #{deploy_to}/#{shared_dir}/assets"
  end

  desc "Copy user-uploaded content from existing installation to shared directory"
  task :copy_content, :roles => :app do
    # reset permissions
    run "chmod -R 777 #{deploy_to}/#{shared_dir}/assets"
  end

  desc "Set the correct permissions for the config files and cache folder"
  task :set_permissions, :roles => :app do
    run "chmod 666 #{current_release}/index.php"
    run "chmod 777 #{current_release}/system/cms/config/"
    run "chmod 666 #{current_release}/system/cms/config/config.php"
    #run "chmod 666 #{current_release}/system/cms/config/database.php"
    run "chmod -R 777 #{current_release}/system/cms/cache/"
  end
  
  desc "Set the correct permissions for the addons and uploads folder"
  task :set_content_permissions, :roles => :app do
    run "chmod -R 777 #{current_release}/addons/"
    run "chmod -R 777 #{current_release}/assets/cache/"
    run "chmod -R 777 #{current_release}/uploads/"
  end

  desc "Create symlinks to shared data such as config files and uploaded images"
  task :create_symlinks, :roles => :app do
    # the config file
    #run "ln -s #{deploy_to}/#{shared_dir}/config/config.php #{current_release}/#{system}/config/config.php" 
    #run "ln -s #{deploy_to}/#{shared_dir}/#{system}/config/database.php #{current_release}/#{system}/config/database.php"
    # standard image upload directories
    run "ln -sf #{deploy_to}/#{shared_dir}/assets/"
  end

  desc "Clear the caches"
  task :clear_cache, :roles => :app do
    run "if [ -e #{current_release}/assets/cache/ ]; then rm -r #{current_release}/assets/cache/*; fi"
  end

end