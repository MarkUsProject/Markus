# Assignment Visibility UI Implementation

## Overview
This document describes the front-end implementation for the assignment visibility settings feature, which allows instructors to configure when students can see assignments both globally and per-section.

## Changes Made

### 1. Locale Updates (`config/locales/views/assignments/en.yml`)
Added new translation keys:
- `assignments.section_hidden.scheduled` - "Visible on/until"
- `assignments.section_hidden.scheduled_description` - Description text
- `assignments.section_hidden.visible_from` - "Visible from"
- `assignments.section_hidden.visible_until` - "Visible until"
- `assignments.section_hidden.visible_from_placeholder` - Placeholder text
- `assignments.section_hidden.visible_until_placeholder` - Placeholder text

### 2. Form Updates (`app/views/assignments/_form.html.erb`)

#### Global Visibility Settings (Lines 91-124)
Replaced the simple Hidden/Visible radio buttons with three options:
1. **Hidden** - Students cannot see the assignment
2. **Visible** - Students can always see the assignment
3. **Visible on/until** - Students can see the assignment during a specific time period
   - Shows datetime fields for `visible_on` and `visible_until` when selected
   - Uses flatpickr for date/time picking (consistent with existing due date fields)

#### Section-Specific Settings (Lines 140-204)
Updated the section properties table to include:
- Added two new columns: "Visible From" and "Visible Until"
- Added "Scheduled" option to the visibility radio buttons for each section
- Datetime inputs are enabled/disabled based on whether "Scheduled" is selected
- Sections can still use "Default" to inherit global settings

#### JavaScript Enhancements (Lines 28-63)
Added interactive behavior:
- `toggleGlobalVisibilityDatetimeFields()` - Shows/hides global datetime fields based on radio selection
- `toggleSectionDatetimeFields()` - Enables/disables section datetime inputs based on visibility selection
- Event listeners on radio buttons to trigger the toggle functions
- Initialization code to set correct state on page load

### 3. Styling
**No custom stylesheets needed!** The implementation uses existing MarkUs styles:
- Uses `inline-labels` class for grid layout (already defined in `_markus.scss`)
- Uses `<span>` elements to match existing radio button patterns
- Section table styling uses existing `.assessment_section_properties_form` styles
- Disabled inputs use browser default styling

## Design Decisions

### 1. Radio Button Approach
- Used radio buttons instead of a dropdown for better visibility of all options
- Follows the existing pattern used for submission rules in the same form

### 2. Inline Datetime Fields
- Global datetime fields appear inline below the "Visible on/until" option
- Section datetime fields are in table columns for better alignment
- Disabled state for section fields when not in "Scheduled" mode

### 3. Backwards Compatibility
The UI maps to the backend fields as follows:
- **Hidden**: `is_hidden = true`, `visible_on = NULL`, `visible_until = NULL`
- **Visible**: `is_hidden = false`, `visible_on = NULL`, `visible_until = NULL`
- **Scheduled**: `is_hidden = false`, `visible_on` and `visible_until` set as specified

### 4. Section Inheritance
- Sections default to "Default" which inherits the global visibility setting
- This is consistent with how section-specific due dates work
- Clear labeling shows what "Default" means in the context

## User Experience Flow

### Creating a New Assignment
1. Instructor selects global visibility (defaults to "Visible")
2. If "Visible on/until" is selected, datetime fields appear
3. If sections exist and section-specific settings are enabled:
   - Each section defaults to "Default" (inherits global)
   - Instructor can override per section by selecting a different option
   - If "Scheduled" is selected for a section, datetime fields become enabled

### Editing an Existing Assignment
1. Form loads with current visibility settings
2. If assignment has `visible_on` or `visible_until` set, "Scheduled" is pre-selected
3. JavaScript initializes the correct show/hide state for all fields
4. Section datetime fields are enabled/disabled based on their visibility setting

## Testing Considerations

### Manual Testing Checklist
- [ ] Create new assignment with "Hidden" visibility
- [ ] Create new assignment with "Visible" visibility
- [ ] Create new assignment with "Scheduled" visibility (both dates)
- [ ] Create new assignment with "Scheduled" visibility (only visible_on)
- [ ] Create new assignment with "Scheduled" visibility (only visible_until)
- [ ] Edit existing assignment and change visibility settings
- [ ] Test section-specific visibility with "Default" option
- [ ] Test section-specific visibility with "Scheduled" option
- [ ] Verify datetime fields show/hide correctly when toggling radio buttons
- [ ] Verify section datetime fields enable/disable correctly
- [ ] Verify flatpickr works on all datetime fields
- [ ] Test with no sections (section table should not appear)
- [ ] Test with multiple sections

### Browser Testing
- [ ] Chrome
- [ ] Firefox
- [ ] Safari
- [ ] Edge

## Future Enhancements

### Potential Improvements
1. **Validation** - Add client-side validation to ensure:
   - If "Scheduled" is selected, at least one datetime is provided
   - `visible_on` is before `visible_until` if both are set

2. **Bulk Actions** - Add "Apply to all sections" button to quickly set all sections

3. **Visual Indicators** - Use icons or color coding to show which sections have overrides

4. **Preview Mode** - Add "Preview as student" to see what different sections would see

5. **Time Zone Display** - Show time zone information next to datetime fields

## Related Files
- Backend model: `app/models/assignment.rb`
- Backend model: `app/models/assessment_section_properties.rb`
- Migration: `db/migrate/20251010150001_update_check_repo_permissions_for_datetime_visibility.rb`
- Controller: `app/controllers/assignments_controller.rb`

## Notes
- This implementation follows the existing MarkUs form conventions exactly
- Uses jQuery (already used throughout the codebase)
- Uses flatpickr for datetime picking (already used for due dates)
- Uses existing MarkUs styles - no custom CSS needed
- No React components needed - pure ERB/jQuery implementation
- Matches the exact pattern of the existing is_hidden radio buttons
