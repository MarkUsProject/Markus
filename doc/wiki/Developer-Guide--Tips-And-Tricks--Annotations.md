# Annotations

When submitted work is graded by a TA, or viewed later on by the student that submitted it, each submitted file may have one or more *annotations* from the TA. (We use the term "annotations" to distinguish that idea from *comments*, since students could have lots of comments in their code that a TA would want to annotate.)

Here's a user story that describes what an annotation more or less is.

## What is an Annotation? A User Story...

Jamie, the TA, is about to grade some C code submitted by c9doej. Jamie pulls up the student source code, and begins to read it through it. Jamie is pleased at how easy the code is to read, because it is syntax highlighted.

Part way down, Jamie notices that c9doej forgot to free some memory that had been malloc'd. "Clearly, this is a memory leak", thinks Jamie. Jamie highlights the part of the code where memory should be freed, and presses the "create new annotation" button. A dialog box comes up, and Jamie types in this annotation:

"You should have freed variable x here. This is a memory leak!"

Jamie presses the submit button, and the lines that Jamie had highlighted glows a different colour than the rest of the source code. When Jamie moves the mouse cursor over the glowing code, a little box pops up to display Jamie's message.

Later on, when all of the assignments have been marked and returned, c9doej logs in to check his grade. Scanning through his code, he sees the glowing lines. He hovers his mouse over the lines and reads Jamie's message. "Of course!", thinks c9doej, "I knew that. Won't make that mistake twice."

## Annotations: The Rules

1. Annotations can be applied to any submitted file type (plaintext, PDF, and images).
2. For plaintext files, annotations are applied on top of the syntax highlighting of the code. We are currently using [Syntax Highlighter 1.5.1](https://github.com/syntaxhighlighter/syntaxhighlighter) for syntax highlighting.
3. Annotations can be removed by after they've been added.
4. Annotations can also be edited. However, if a TA edits a "reusable" annotation (see below), this will change that annotation for all places where it was used added.

### Common/Reusable Annotations

Annotations can be *common* or *reusable*. This is for when an annotation is used for several different submissions or several places in the same submission, for example, if students are consistently writing code lines longer than 80 characters.
Each reusable annotation belongs to an *annotation category*. For example, an annotation talking about long code lines would probably be put under a category called "Style".
Each assignment has its own annotation categories.

### On-the-fly Annotations

Annotations can also be added on-the-fly for a particular submission. For example, if c9doej submits some code where a few lines are completely unreadable, the TA might write a unique annotation just for that student.
When TAs press the "Create New Annotation" button, a dialog comes up for the annotation text. This dialog will also ask them which category they would like to add this annotation to if they want it to be "canned". The default is to leave the annotation category as "uncategorized", meaning that it's an on-the-fly annotation not meant to be added to multiple students.


## Implementation Details

### Models

There are three models that deal with annotations: `AnnotationCategory`, `AnnotationText`, and `Annotation`.

- `AnnotationCategory`: a group of reusable annotations. It belongs to an `Assignment`, and has many `AnnotationText`s. It has a name for the category, like `'Style'` or `'Memory Management'`. Only admins can create annotation categories.
- `AnnotationText` contains the actual text content of an annotation. Each `AnnotationText` optionally belongs to an `AnnotationCategory`; if the association is `nil`, this text is an on-the-fly annotation, used for just a single submission file.
- `Annotation`: an actual annotation given by a TA for a submission. It belongs to a `SubmissionFile` *and* `AnnotationText`, and also contains information about where the annotation occurs. These "location" columns are all nullable because they only apply to certain kinds of submission files.

### JavaScript / Client Side

#### Source Code Glower

The code that handles the client-side Annotation behaviour can be found here:

/public/javascripts/SourceCodeGlower

Inside is a series of files - each file defines a particular JavaScript Class. Here is a description of the files/classes, and how they function with each other:

##### SourceCodeAdapter.js and SyntaxHighlighter1p5Adapter.js

The current client-side approach to Syntax Highlighting is something I figured might change over time. We might upgrade the Syntax Highlighter to a newer version for better performance, or change to a different library completely (perhaps a server side one).

Because of the possibility of change, I did my best to decouple the Syntax Highlighter from the Source Code Glower. That way, if we did end up changing the Syntax Highlighter library, all of the necessary changes would have to be made in a single file, and the rest of the system should still be OK.

SourceCodeAdapter is an abstract class. Here is a list of the responsibilities for any implementation of SourceCodeAdapter:

-   To take the root of some DOM element that contains syntax highlighted source code in the constructor

-   To return an Enumerable collection of SourceCodeLine's (a class that I'll discuss in the next section) from that DOM element, using the method getSourceNodes().

-   Given some DOM element X, to determine whether or not X is in the currently highlighted source code, and to return the DOM element that represents the root of a SourceCodeLine. The method for this is getRootFromSelection(some\_node). This is important for determining which lines are selected after highlighting the source with the mouse cursor.

-   To perform any run-time hackery on the syntax highlighter DOM element, using applyMods().

SyntaxHighlighter1p5Adapter is the concrete class that implements SourceCodeAdapter for the current version of the Syntax Highlighter that we're using. In applyMods, this is where I've stuffed the "A+" and "A-" text-size adjuster functions that are visible in the source code pane menu.

##### SourceCodeLine.js and SyntaxHighlighter1p5Line.js

SourceCodeLine is the other part of the decoupling between a syntax highlighting implementation and Source Code Glower.

SourceCodeLine represents a single line of source code. The SourceCodeAdapter should return one of these for every syntax highlighted line.

SourceCodeLine is an abstract class. Here is a partial list of the responsibilities for any implementation of SourceCodeLine:

-   To take a DOM element that represents a single source code line in the constructor, and to remember it for future manipulation

-   To manage glowing on that single source code line using the method glow(). The glow() method will increase the glow\_depth on this source code line to an arbitrary amount. Similarly, unGlow() will decrease the glow\_depth.

-   After every glow() or unGlow() call, this class will also decorate the source code DOM element with a CSS class representing the depth of the glow. The CSS class is prefixed "source\_code\_glowing\_" followed by the depth of the glow. For example, a line of source code that has been "glowed" once, would have a CSS class "source\_code\_glowing\_1" applied to it. Similarly, once unGlow() has been called, the appropriate CSS classes will be removed.

-   Before and after every glow() and unGlow() call, there are hook functions that must be implemented. They are beforeGlow(), afterGlow(), beforeUnGlow(), and afterUnGlow().

-   To handle the mouseover/mouseout events on the source code line DOM element. This class remembers the functions that are associated with mouseover/mouseout events for easy stopObserving. Observations are set with the method observe(over\_func, out\_func), where the desired mouseover/mouseout functions are passed. stopObserving removes these functions.

SyntaxHighlighter1p5Line is the concrete class that implements SourceCodeLine for the current version of the Syntax Highlighter that we're using. This implementation handles a special case for this particular Highlighter - with Syntax Highlighter, alternating lines are given a CSS class "alt". This class needs to be removed for the glow CSS class to work properly, but also needs to be put back when all glows are removed. This implementation makes use of the beforeGlow(), afterGlow(), beforeUnGlow(), afterUnGlow() hooks to handle this case.

##### SourceCodeLineFactory.js

SourceCodeLineFactory is where concrete implementations of SourceCodeLine are cranked out. If the current Syntax Highlighter is changed, and a new SourceCodeLine class is written, this Factory must be altered or replaced to return the new class of SourceCodeLines.

##### SourceCodeLineCollection.js and SourceCodeLineArray.js

The SourceCodeLineCollection is the class that maps SourceCodeLines to particular line\_numbers. This class is a result of me being unsure of how I wanted to represent collections of SourceCodeLines: as an array with each index being the line number, or a hash with each key being the line\_number. In the end, I decided that since I might change my mind about this, to create my own SourceCodeLineCollection class to represent these collections.

Here is a list of the responsibilities for an implementation of SourceCodeLineCollection:

-   To remember a SourceCodeLine for a particular line number, using the set(line\_num, source\_code\_line) method

-   To return the correct SourceCodeLine given a particular line number, using the get(line\_num) method

-   To provide a function for iteration, using each(function(source\_code\_line))

-   Given a DOM element that *may* represent a single SourceCodeLine, to return the line\_number of that node of its found in the SourceCodeLineCollection.

SourceCodeLineArray is the concrete class that implements SourceCodeLineCollection with an Enumerable Array.

##### SourceCodeLineManager.js

This class is responsible for managing and manipulating the SourceCodeLineCollection and SourceCodeLines. It's really just a simple way of binding SourceCodeLineCollections and SourceCodeLines, while reducing coupling.

-   The constructor SourceCodeLineManager(adapter, line\_factory, empty\_collection) takes a SourceCodeAdapter, a SourceCodeLineFactory, and an empty SourceCodeLineCollection to start.

-   getLineNumber(line\_node) returns the line number given a particular DOM node. This returns -1 if no node is found.

-   getLine(line\_num) returns the SourceCodeLine, given a line\_number.

##### AnnotationLabel.js

This class represents the Annotation Label in the client-side memory. Its main responsibility is to remember the content of a particular Annotation Label, and to be updated when Annotation Labels are updated on the server side.

-   Constructor is as follows: AnnotationLabel(annotation\_label\_id, annotation\_category\_id, content)

-   setContent(content) can be used to set the new Annotation Label content

-   getContent() returns the Annotation Label content

-   getId() returns the annotation\_label\_id

-   getCategoryId() returns the annotation\_category\_id

##### AnnotationLabelDisplayer.js

This class is in charge of displaying collections of Annotations on the screen. Annotation Labels are displayed in a dynamically generated DIV that is appended to a parent\_node that is attached to the constructor. This generated DIV is hidden until needed, and is styled with CSS class "annotation\_label\_display".

The two variables LABEL\_DISPLAY\_X\_OFFSET and LABEL\_DISPLAY\_Y\_OFFSET offset where the annotation display appears in relation to the mouse cursor.

##### AnnotationLabelManager.js

The AnnotationLabelManager is similar to the SourceCodeLineManager - it stores annotation labels within itself based on annotation\_ids. It has the following methods:

-   annotationLabelExists(annotation\_label\_id) - returns true/false based on whether or not an annotation\_label is registered at annotation\_label\_id.

-   getAnnotationLabel(annotation\_label\_id) - returns the Annotation Label registered under annotation\_label\_id

-   addAnnotationLabel(annotation\_label) - interrogates an Annotation Label for its ID, and attempts to add it to the internal collection of Annotation Labels. If an Annotation Label already exists at the given ID, an exception is thrown.

-   getAllAnnotationLabels() - returns an array of all of the Annotation Labels

##### SourceCodeLineAnnotations.js

This is the big one. The SourceCodeLineAnnotations is what does most of the heavy lifting, and is the connector between SourceCodeLines, and Annotation Labels.

In the constructor to a SourceCodeLineAnnotations object, an AnnotationLabelManager, a SourceCodeLineManager, and an AnnotationLabelDisplayer must be passed in - this is where all the objects interact, and where manipulations across objects occurs.

I'm just going to list off the methods for this object one by one, giving a description of what they do.

-   getLineManager() - returns the SourceCodeLineManager

-   getAnnotationLabelManager() - returns the AnnotationLabelManager

-   getAnnotationLabelDisplayer() - returns the AnnotationLabelDisplayer

-   annotateLine(annotation\_id, line\_num, annotation\_label\_id) given an annotation\_id, a line\_num of a single source code line, and an annotation\_label\_id, annotate that line such that this source code line glows, and displays its annotations once the mouse cursor is hovered over it.

-   annotateRange(annotation\_id, range, annotation\_label\_id) uses the $R range object from the Prototype library. For each line number in range, an annotation is created using annotateLine.

-   removeAnnotationFromLine(annotation\_id, line\_num, annotation\_label\_id) remove a layer of glow off of the appropriate source code line, and remove the annotation associated with that source code line. If there are no more annotations on this source code line, stop observing it for mouseover/mouseout events.

-   removeAnnotationFromRange(annotation\_id, range, annotation\_label\_id) uses the $R range object from the Prototype library. For each line number in range, remove the annotation using removeAnnotationFromLine

-   registerAnnotationLabel(annotation\_label) - if a new annotation label is created, add it to the annotation label manager.

-   addRelationship(annotation\_id, line\_num, annotation\_label\_id) - associate a particular source code line with a particular annotation\_label

-   getRelationships() - return a collection of all source code line / annotation label relationships

-   setRelationships() - replace the collection of source code line / annotation label relationships

-   relationshipExists(annotation\_id, line\_num, annotation\_label\_id) - returns true or false based on whether or not a relationship exists between a line\_number, an annotation\_label\_id, and an annotation\_id

-   removeRelationship(annotation\_id, line\_num, annotation\_label\_id) - removes the relationship between an annotation\_id, line\_num, and annotation\_label\_id.

-   getAnnotationLabelsForLineNum(line\_num) - given a line number, return all annotation labels associated with that source code line

-   hasAnnotation(line\_num) - returns true/false based on whether or not a source code line has any annotations connected to it

-   hideLabel() - hide the AnnotationLabelDisplayer dynamically generated div

-   displayLabelsForLine(line\_num, x, y) for a given line number, send a collection of associated annotation labels (if any) to the AnnotationLabelDisplayer, with instructions to place the display at coordinates x and y.

#### Working the Source Code Glower

As of this writing, we're still using Syntax Highlighter 1.5.1. Therefore, we have to wait for the source code to by syntax highlighted on the client-side before any annotations can be added to the student code.

This behaviour is triggered here:

/app/views/annotations/\_codeviewer.html.erb (NOTE - this may have been moved after this was written...I know there was talk of refactoring the grader out of the annotations controller)

Once the dp.SyntaxHighlighter.HighlightAll('code') call is complete, sourceCodeReady() is called. This function is currently in the grader view code here:

/app/views/annotations/grader.html.erb (again, note that this may have been moved - see above for \_codeviewer)

##### SourceCodeReady()

Here, a SourceCodeAdapter is created for the newly syntax highlighted code. The Adapter prepares a collection of DOM elements for conversion to Source Code Lines, and also applies the modifications to the Syntax Highlighted code that allow for increasing/decreasing font size.

An empty SourceCodeLineCollection (in the current version, SourceCodeLineArray) is created. A SourceCodeLineFactory is created. A SourceCodeLineManager is created using the SourceCodeAdapter, the SourceCodeLineFactory, and the SourceCodeLineCollection.

An AnnotationLabelManager is created. An AnnotationLabelDisplayer is created, and fed the DOM node of an empty DIV somewhere on the page for the Displayer to append it's dynamically generated DIV to. It really doesn't matter where that root DIV is, since the dynamically generated DIV will position itself *absolute*-ly.

Finally, the SourceCodeLineAnnotations object is created using the SourceCodeLineManager, AnnotationLabelManager, and AnnotationLabelDisplayer. The SourceCodeLineAnnotations is held in a global variable called **line\_annotations**.

##### line\_annotations

line\_annotations is called and manipulated by basic Javascript functions: add\_annotation\_label, add\_annotation, remove\_annotation, update\_annotation\_label.

And that's how the annotations more or less work.
