# Configuration for the 'activejob-status' gem

# Use the ActiveSupport#lookup_store syntax
ActiveJob::Status.store = :redis_cache_store
