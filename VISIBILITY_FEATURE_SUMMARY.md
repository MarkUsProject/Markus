# Assignment Visibility Settings - Feature Summary

## Overview
Implemented a comprehensive UI for managing assignment visibility with datetime-based scheduling, supporting both global and section-specific settings.

## Features Implemented

### 1. Global Visibility Settings
Three radio options for assignment visibility:
- **Hidden** - Students cannot see the assignment
- **Visible** - Students can always see the assignment
- **Visible on/until** - Students can see the assignment during a specific time period
  - Shows two datetime fields when selected: "Visible from" and "Visible until"
  - Both fields are optional (can set just start, just end, or both)

### 2. Section-Specific Visibility Overrides
When section-specific settings are enabled, each section can have its own visibility:
- **Default** - Use the global visibility setting
- **Visible** - Override to make visible for this section
- **Hidden** - Override to hide for this section
- **Scheduled** - Override with section-specific datetime range

### 3. UI/UX Features
- Radio buttons positioned to the left of labels for better UX
- Datetime fields appear/disappear dynamically based on selection
- Flatpickr date picker integration for easy datetime selection
- Section datetime inputs auto-enable/disable based on "Scheduled" selection
- Form correctly preserves "Scheduled" selection when reloading

## Files Modified

### Frontend
- **`app/views/assignments/_form.html.erb`**
  - Added "Default Visibility" section with three radio options
  - Added datetime input fields for global visibility
  - Updated section table with visibility column and datetime columns
  - Added JavaScript to handle show/hide and enable/disable logic

- **`app/views/assignments/_boot.js.erb`**
  - Added flatpickr initialization for `visible_on` and `visible_until` fields

- **`config/locales/views/assignments/en.yml`**
  - Added locale strings for all new UI elements
  - Updated help text to be more user-friendly

### Backend
- **`app/controllers/assignments_controller.rb`**
  - Added `:visible_on` and `:visible_until` to permitted parameters
  - Added logic to convert `is_hidden="scheduled"` to `is_hidden=false` with datetime values
  - Handles both global and section-specific "scheduled" conversion

### Tests
- **`spec/controllers/assignments_controller_spec.rb`**
  - Added 6 comprehensive tests for visibility settings:
    - Creating assignment with scheduled visibility
    - Converting "scheduled" to `is_hidden=false`
    - Updating assignment with scheduled visibility
    - Clearing datetime values when switching modes
    - Section-specific scheduled visibility creation
    - Section-specific scheduled visibility updates

## Technical Details

### Data Model
- `visible_on` and `visible_until` columns exist on the `assessments` table (not `assignment_properties`)
- Section-specific datetime columns on `assessment_section_properties` table
- When `is_hidden="scheduled"` is submitted, controller converts to `is_hidden=false` with datetime values

### Form Logic
- **On Load**: Checks if datetime values exist → if yes, select "Scheduled" radio button
- **On Change**: Show/hide datetime fields based on radio selection
- **On Save**: Convert "scheduled" value to `is_hidden=false` before saving

### JavaScript IDs
- Global fields: `#assignment_visible_on`, `#assignment_visible_until`
- Section fields: Use `.section-datetime-input` class

## Design Decisions

1. **No Custom CSS**: Used existing MarkUs `inline-labels` grid layout for consistency
2. **Locale Strings**: All user-facing text uses I18n for internationalization
3. **Radio Before Label**: Improved UX by placing radio buttons left of labels
4. **Explicit "Scheduled" Option**: Clear indication that datetime scheduling is active
5. **Optional Datetime Fields**: Both start and end times are optional for flexibility

## Testing
All tests pass successfully:
```
6 examples, 0 failures
```

Tests cover:
- Creating assignments with scheduled visibility
- Updating assignments with scheduled visibility
- Section-specific scheduled visibility
- Proper conversion of "scheduled" to `is_hidden=false`

## Next Steps (Future Work)
- Add client-side validation to ensure `visible_until` is after `visible_on`
- Add visual indicators on assignment list showing scheduled visibility status
- Consider adding timezone display for datetime fields
- Add tests for edge cases (e.g., overlapping datetime ranges)
