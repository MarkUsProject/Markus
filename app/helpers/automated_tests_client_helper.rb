module AutomatedTestsClientHelper
  ASSIGNMENTS_DIR = File.join(MarkusConfigurator.autotest_client_dir, 'assignments').freeze
  STUDENTS_DIR = File.join(MarkusConfigurator.autotest_client_dir, 'students').freeze
  HOOKS_FILE = 'hooks.py'.freeze
  SPECS_FILE = 'specs.json'.freeze
end
