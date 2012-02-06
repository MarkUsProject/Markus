================================================================================
Notes System
================================================================================

What is the notes system?
================================================================================

The notes system allows instructors and TAs to add notes on various objects
during marking or otherwise during the course of the term. Currently, this
functionality is only available for groupings.

Why do we want this feature?
================================================================================

If a student is sick or has other extenuating circumstances, then we would
like for the instructor and TAs to have a way of communicating about these
issues from within the MarkUs environment, while being able to see the context
where these problems matter, rather than having separate e-mail threads about
them. This way, all TAs and instructors for the course can also see the notes.

How do notes work?
================================================================================

An instructor or a TA can create a note on a grouping while marking the
assignment. An instructor can also create a note on a grouping in the "Groups
& Graders" screen on the "Assignments" tab. All TAs and instructors can also
see these notes in a summary view on the Notes tab and create additional notes
via a screen there.

All instructors can edit and delete all notes. A TA can edit and delete notes
created by him/herself.

Notes are set up in their associated noteable objects to be deleted on destroy
of the associated object.

User interface
================================================================================

Notes tab
--------------------------------------------------------------------------------

For TAs and instructors, a new tab for Notes was added to the end of the row
of tabs.

Summary view
********************************************************************************

Clicking on the Notes tab presents you with a link to add a new note, as well
as a summary view of all the existing notes. For each note, there are three
columns:

* The first column shows the author's username, the noteable's "display_for_note" and the creation time of the note. (See the Noteable section below for information on this method.)
* The second column shows the note's message.
* The third column shows Edit and Delete links, if the current user has the ability to perform these actions on the note.

Editing a note
********************************************************************************

The Edit a note screen displays the pertinent information on the note:

* Author
* Noteable object (type and display_for_note)
* Creation time

and offers a textarea to edit the note message. This is the only field that is editable.

Create a note
********************************************************************************

The Create a note screen allows the user to create a note on a specific
grouping. Currently this is done by first selecting the assignment from a
dropdown and then a dropdown is populated with all of the groupings on that
assignment. The user then selects the correct grouping, enters a message and
clicks "Save".

Groups & Graders
--------------------------------------------------------------------------------

Submissions
--------------------------------------------------------------------------------

Implementation details
================================================================================

### Database

The database for the Notes system is quite simple. It only requires one table, notes:

* <code>notes_message: string</code> The message that the author wanted to express in this note
* <code>creator_id: integer</code> The user ID of the author of this note
* <code>noteable_id: integer</code> The ID of the object associated with this note
* <code>noteable_type: string</code> The type of the object associated with this note

Each row in this table represents a single note. A Polymorphic association is
used to link the note to its associated object, which is represented in the
database by the columns noteable_id and noteable_type. This object can be
accessed via @note.noteable, regardless of its type.

Noteable
--------------------------------------------------------------------------------

Each object that is noteable has a "display_for_note" method that specifies
how to show it as an object for the Notes summary.

Grouping displays itself as as "A#: Group_000#" or "A#: Group_000#: userid1,
userid2"

Controller code
--------------------------------------------------------------------------------

There is one controller for the notes system - NoteController. This controller
contains actions for both the modal dialogs as well as for the Notes tab.

Prior to all actions, we ensure that the current user is a TA or an admin and
for the edit and delete actions that the current user is allowed to modify the
requested note.

Modal dialogs
********************************************************************************

Actions:

* notes_dialog - FILL IN
* add_note - FILL IN

Notes tab
********************************************************************************

Actions:

* **index** - Retrieves all notes, in descending order by creation time.
* **new** - Retrieves all assignments and the groupings for the first assignment to display the new note form.
* **create** - Processes the new note form; redirects to the index page after successful completion.
* **new_update_groupings** - Retrieves groupings on a change in assignment in the new note form
* **edit** - Retrieves the note information to display the edit a note form.
* **update** - Processes the edit note form; redirects to the index page after successful completion.
* **delete** - Deletes the given note and sets the flash accordingly.

Views
--------------------------------------------------------------------------------

Modal dialogs
********************************************************************************

These are located in the "modal_dialogs" folder in the note controller's views.

FILL IN

Notes tab
********************************************************************************

* **delete** - Redirects to the index action upon deletion, regardless of success or failure, since either message will be shown in the flash.
* **edit** - Displays the edit form, as described above in the user interface section.
* **index** - Shows all the notes, as described above for the "Summary view" in the user interface section. Above the notes, shows any error and success messages.
* **new_update_groupings** - Replaces the groupings dropdown with a new one with the new @groupings values.
* **new** - Displays the new form, as described above in the user interface section.

Tests
--------------------------------------------------------------------------------

Unit tests
********************************************************************************

The unit tests test the associations in the Note model and the
validate_presence_of macros.

Functional tests
********************************************************************************

The functional tests assert the following:

* An authenticated student can make no GET, POST, or DELETE requests against the NoteController actions.
* An authenticated TA or admin can make GET requests against the notes_dialog, index, new, new_update_groupings, edit; POST requests against the add_note, create, update; DELETE request against delete.
* An authenticated TA can edit and delete only his/her notes and not anyone else's, but an admin can edit and delete anyone's.

Current state and potential additions
--------------------------------------------------------------------------------

