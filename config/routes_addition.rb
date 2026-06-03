# Add this route in config/routes.rb.
# Recommended placement: inside the course/assignment scope if your MarkUs routes already nest submissions under courses and assignments.
# Minimal API-style route used by the JupyterLab extension:

post 'api/jupyter_submissions', to: 'api/jupyter_submissions#create'

# Alternative nested route if you prefer course/assignment IDs in the URL:
# post 'courses/:course_id/assignments/:assignment_id/jupyter_submit', to: 'api/jupyter_submissions#create'
