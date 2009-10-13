% -*-CLWEB-*-

\newif\ifzapf \zapffalse
\ifzapf
\input palatino
\input euler
\font\tenrmr=pplr8r at 10pt % for non-ASCII characters
\def\ldq{{\tenrmr \char'253}} % left guillemet
\def\rdq{{\tenrmr \char'273}} % right guillemet
\font\tenss=lopr8r at 10pt
\font\tenssi=lopri8r at 10pt
\font\tenssb=lopb8r at 10pt
\let\cmntfont=\tenssi
\mainfont
\def\({\bgroup\IB\it} % use italics for inner-Lisp mode material
\def\){\/\egroup}
{\catcode`\(=\active \catcode`\)=\active
 % borrow Palatino's parenthesis for Lisp code
 \gdef({{\tenrm\char`\(}\kern.025em}
 \gdef){{\tenrm\char`\)}\kern.025em}}
\def\csc#1{{\sc #1}}
\def\lheader{\headertrue\mainfont\the\pageno\sc\qquad\grouptitle
  \hfill\lowercase\expandafter{\jobname}\qquad
  \mainfont\topsecno} % top line on left-hand pages
\def\rheader{\headertrue\mainfont\topsecno
  \sc\qquad\lowercase\expandafter{\jobname}\hfill
  \grouptitle\qquad\mainfont\the\pageno} % top line on right-hand pages
\def\grouptitle{\let\i=I\let\j=J\lowercase\expandafter{\expandafter
                        \takethree\topmark}}
\else
\def\ldq{\relax} % left guillemet
\def\rdq{\relax} % right guillemet
\def\csc#1{{\sc\uppercase{#1}}}
\fi

\def\pb{\.{|...|}} % program brackets
\def\v{\.{\char'174}} % vertical bar in typewriter font
\def\WEB{{\tt WEB}}
\def\CWEB{{\tt CWEB}}
\def\CLWEB{{\tt CLWEB}}
\def\EOF{\csc{eof}}
\def\etc.{{\it \char`&c.\spacefactor1000}}
\def\metasyn#1{$\langle${\it #1\/}$\rangle$} % metasyntactic variable
\def\cltl{\csc{cl}t\csc{l}-2} % Common Lisp, the Language (2nd ed.)

@*Introduction. This is \CLWEB, a literate programming system for Common
Lisp by Alex Plotnick \metasyn{plotnick@@cs.brandeis.edu}. It is modeled
after the \CWEB\ system by Silvio Levy and Donald E.~Knuth, which was in
turn adapted from Knuth's original \WEB\ system. It shares with those
earlier systems not only their underlying philosophy, but also most of
their syntax and control codes. Readers unfamiliar with either of them---or
with literate programming in general---should consult the \CWEB\ manual or
Knuth's {\it \ldq Literate Programming\rdq} (\csc{csli}:~1992).

This is a preliminary, $\alpha$-quality release of the system; for the
latest version, please visit\par\noindent
\.{http://www.cs.brandeis.edu/\~plotnick/clweb/}.

@ A \CLWEB\ source file consists of a mixture of \TeX, Lisp, and \WEB\
control codes, but which is primary depends on your point of view. The
\CWEB\ manual, for instance, says that ``[w]riting \CWEB\ programs is
something like writing \TeX\ documents, but with an additional `C mode'
that is added to \TeX's horizontal mode, vertical mode, and math mode.''
The same applies, {\it mutatis mutandis,} to the current system, but one
might just as easily think of a web as some code with documentation blocks
and special control codes sprinkled throughout, or as a completely separate
language containing blocks that happen to have the syntax (more or less) of
\TeX\ and Lisp. For the purposes of understanding the implementation, this
last view is perhaps the most useful, since the control codes determine
which syntax to use in reading the material that follows.

The syntax of the \CLWEB\ control codes themselves is similar to that of
dispatching reader macro characters in Lisp: they all begin with
`\.{@@}$x$', where~$x$ is a single character that selects the control code.
Most of the \CLWEB\ control codes are quite similar to the ones used in
\CWEB; see the \CWEB\ manual for detailed descriptions of the individual
codes.

@ A literate programming system provides two primary operations:
{\it tangling\/} and {\it weaving\/}. The tangler prepares a literate 
program, or {\it web}, for evaluation by a machine, while the weaver
prepares it for typesetting and subsequent reading by a human. These
operations reflect the two uses of a literate program, and the two
audiences by whom it must be read: the computer on the one hand, and the
human programmers that must understand and maintain it on the other.

Our tangler has two main interface functions: |tangle-file| and |load-web|.
The first is analogous to |cl:compile-file|: given a file containing \CLWEB\
source, it produces an output file that can be subsequently loaded into a
Lisp image with |load|. The function |load-web| is analogous to |cl:load|,
but also accepts \CLWEB\ source as input instead of ordinary Lisp source:
it loads a web into the Lisp environment.

The weaver has a single entry point: |weave| takes a web as input and
generates a file that can be fed to \TeX\ to generate a pretty-printed
version of that web.

@ We'll start by setting up a package for the system. In addition to the
top-level tangler and weaver functions mentioned above, there's a fourth
exported function, |load-sections-from-temp-file|, that is conceptually
part of the tangler, but is a special-purpose routine designed to be used
in conjunction with an editor such as Emacs to provide incremental
redefinition of sections; the user will generally never need to call it
directly. The remainder of the exported symbols are condition classes for
the various errors and warnings that may be generated while processing a
web.

@l
(provide "CLWEB")

@e
(eval-when (:compile-toplevel :load-toplevel :execute)
  #+sbcl (require 'sb-cltl2))
@e
(defpackage "CLWEB"
  (:use "COMMON-LISP"
        #+sbcl "SB-CLTL2"
        #+allegro "SYS")
  (:export "TANGLE-FILE"
           "LOAD-WEB"
           "WEAVE"
           "LOAD-SECTIONS-FROM-TEMP-FILE"
           "AMBIGUOUS-PREFIX-ERROR"
           "SECTION-NAME-CONTEXT-ERROR"
           "SECTION-NAME-USE-ERROR"
           "SECTION-NAME-DEFINITION-ERROR"
           "UNUSED-NAMED-SECTION-WARNING")
  (:shadow "ENCLOSE"
           #+allegro "FUNCTION-INFORMATION"
           #+allegro "VARIABLE-INFORMATION"))
@e
(in-package "CLWEB")

@t*Test suite. The test suite for this system uses Richard Waters's
\csc{rt} library, a copy of which is included in the distribution. For more
information on \csc{rt}, see Richard C.~Waters, ``Supporting the Regression
Testing of Lisp Programs,'' {\it SIGPLAN Lisp Pointers}~4, no.~2 (1991):
47--53.

We use the sleazy trick of manually importing the external symbols of
the \csc{rt} package instead of the more sensible |(use-package "RT")|
because many compilers issue warnings when the use-list of a package
changes, which would occur if the |defpackage| form above were evaluated
after the tests have been loaded.

@l
(in-package "CLWEB")
@e
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require 'rt)
  (loop for symbol being each external-symbol of (find-package "RT")
        do (import symbol)))

@ We'll define our global variables and condition classes as we need them,
but we'd like them to appear near the top of the tangled output.

@l
@<Global variables@>
@<Condition classes@>

@*Sections. The fundamental unit of a web is the {\it section}, which may
be either {\it named\/} or~{\it unnamed\/}. Named sections are conceptually
very much like parameterless macros, except that they can be defined
piecemeal. The tangler replaces references to a named section with all of
the code defined in all of the sections with that name. (This is where the
name `tangling' comes from: code may be broken up and presented in whatever
order suits the expository purposes of the author, but is then spliced back
together into the order that the programming language expects.) Unnamed
sections, on the other hand, are evaluated or written out to a file for
compilation in the order in which they appear in the source file.

Every section is assigned a number, which the weaver uses for generating
cross-references. The numbers themselves never appear in the source file:
they are generated automatically by the system.

Aside from a name, a section may have a {\it commentary part\/}, optionally
followed by a {\it code part}. (We don't support the `middle' part of a
section that \WEB\ and \CWEB's sections have, since the kinds of definitions
that can appear there are essentially irrelevant in Lisp.)  The commentary
part consists of \TeX\ material that describes the section; the weaver
copies it (nearly) verbatim into the \TeX\ output file, and the tangler
ignores it. The code part contains Lisp forms and named section references;
the tangler will eventually evaluate or compile those forms, while the
weaver pretty-prints them to the \TeX\ output file.

Three control codes begin a section: \.{@@\ }, \.{@@*}, and \.{@@t}.
Most sections will begin with \.{@@\ }: these are `regular' sections,
which might be named or unnamed.

@l
(defclass section ()
  ((name :accessor section-name :initarg :name)
   (number :accessor section-number)
   (commentary :accessor section-commentary :initarg :commentary)
   (code :accessor section-code :initarg :code))
  (:default-initargs :name nil :commentary nil :code nil))

@ Sections introduced with \.{@@*} (`starred' sections) begin a new major
group of sections, and get some special formatting during weaving. The
control code \.{@@*} should be immediately followed by a title for this
group, terminated by a period. That title will appear as a run-in heading
at the beginning of the section, as a running head on all subsequent pages
until the next starred section, and in the table of contents.

The tangler does not care about the distinction between sections with stars
and ones with none upon thars.

@l
(defclass starred-section (section) ())

@ Sections that begin with \.{@@t} are {\it test sections}. They are used to
include test cases alongside the normal code, but are treated specially by
both the tangler and the weaver. The tangler writes them out to a seperate
file, and the weaver may elide them entirely.

Test sections are automatically associated with the last non-test section
defined, on the assumption that tests will be defined immediately after the
code they're designed to exercise.

@l
(defclass test-section (section)
  ((test-for :accessor test-for-section :initform *current-section*)))

(defclass starred-test-section (test-section starred-section) ())

@ There can also be \TeX\ text preceding the start of the first section
(i.e., before the first \.{@@\ } or \.{@@*}), called {\it limbo text}.
Limbo text is generally used to define document-specific formatting
macros, set up fonts, \etc. The weaver passes it through virtually verbatim
to the output file (only replacing occurrences of `\.{@@@@}' with~`\.{@@}'),
and the tangler ignores it completely.

A single instance of the class |limbo-section| contains the limbo text in
its |commentary| slot; it will never have a code part.

@l
(defclass limbo-section (section) ())

@ Whenever we create a non-test section, we store it in the global
|*sections*| vector and set its number to its index therein. This means
that section objects won't be collected by the \csc{gc} even after the
tangling or weaving has completed, but there's a good reason: keeping them
around allows incremental redefinition of a web, which is important for
interactive development.

We'll also keep the global variable |*current-section*| pointing to the
last section (test or not) created.

@<Global variables@>=
(defvar *sections* (make-array 128 :adjustable t :fill-pointer 0))
(defvar *current-section* nil)

@ @<Initialize global variables@>=
(setf (fill-pointer *sections*) 0)
(setf *current-section* nil)

@ Here's where section numbers are assigned. We use a generic function
for |push-section| so that we can override it for test sections.

@l
(defgeneric push-section (section))
(defmethod push-section ((section section))
  (setf (section-number section) (vector-push-extend section *sections*))
  section)

(defmethod initialize-instance :after ((section section) &rest initargs &key)
  (declare (ignore initargs))
  (setq *current-section* (push-section section)))

@t We bind |*sections*| in this test to avoid polluting the global sections
vector.

@l
(deftest current-section
  (let ((*sections* (make-array 1 :fill-pointer 0)))
    (eql (make-instance 'section) *current-section*))
  t)

@ Test sections aren't stored in the |*sections*| vector; we keep them
separate so that they won't interfere with the numbering of the other
sections.

@<Global variables@>=
(defvar *test-sections* (make-array 128 :adjustable t :fill-pointer 0))

@ @<Initialize global variables@>=
(setf (fill-pointer *test-sections*) 0)

@ @l
(defmethod push-section ((section test-section))
  (let ((*sections* *test-sections*))
    (call-next-method)))

@ The test sections all get woven to a seperate output file, and we'll
need a copy of the limbo text there, too.

@l
(defmethod push-section :after ((section limbo-section))
  (vector-push-extend section *test-sections*))

@ We keep named sections in a binary search tree whose keys are section
names and whose values are code forms; the tangler will replace references
to those names with the associated code. We use a tree instead of, say,
a hash table so that we can support abbreviations (see below).

@l
(defclass binary-search-tree ()
  ((key :accessor node-key :initarg :key)
   (left-child :accessor left-child :initarg :left)
   (right-child :accessor right-child :initarg :right))
  (:default-initargs :left nil :right nil))

@ The primary interface to the \csc{bst} is the following routine, which
attempts to locate the node with key |item| in the tree rooted at |root|.
If it is not already present and the |:insert-if-not-found| argument
is true, a new node is created with that key and added to the tree. The
arguments |:predicate| and |:test| should be designators for functions
of two arguments, both of which will be node keys; |:predicate| should
return true iff its first argument precedes its second in the total
ordering used for the tree, and |:test| should return true iff the two
keys are to be considered equivalent.

Two values are returned: the node with key |item| (or |nil| if no such node
was found and |:insert-if-not-found| is false), and a boolean representing
whether or not the node was already in the tree.

@l
(defgeneric find-or-insert (item root &key predicate test insert-if-not-found))

(defmethod find-or-insert (item (root binary-search-tree) &key
                           (predicate #'<) (test #'eql)
                           (insert-if-not-found t))
  (flet ((lessp (item node) (funcall predicate item (node-key node)))
         (samep (item node) (funcall test item (node-key node))))
    (do ((parent nil node)
         (node root (if (lessp item node)
                        (left-child node)
                        (right-child node))))
        ((or (null node) (samep item node))
         (if node
             (values node t)
             (if insert-if-not-found
                 @<Insert a new node with key |item| and return it@>
                 (values nil nil)))))))

@ @<Insert a new node...@>=
(let ((node (make-instance (class-of root) :key item)))
  (when parent
    (if (lessp item parent)
        (setf (left-child parent) node)
        (setf (right-child parent) node)))
  (values node nil))

@t@l
(deftest (bst 1)
  (let ((tree (make-instance 'binary-search-tree :key 0)))
    (find-or-insert -1 tree)
    (find-or-insert 1 tree)
    (values (node-key tree)
            (node-key (left-child tree))
            (node-key (right-child tree))))
  0 -1 1)

(deftest (bst 2)
  (let ((tree (make-instance 'binary-search-tree :key 0))
        (numbers (cons 0 (loop with limit = 1000
                               for i from 1 to limit
                               collect (random limit)))))
    (dolist (n numbers)
      (find-or-insert n tree))
    (let ((keys '()))
      (labels ((traverse-in-order (node)
                 (when node
                   (traverse-in-order (left-child node))
                   (push (node-key node) keys)
                   (traverse-in-order (right-child node)))))
        (traverse-in-order tree)
        (equal (nreverse keys)
               (remove-duplicates (sort numbers #'<))))))
  t)

(deftest bst-find-no-insert
  (let ((tree (make-instance 'binary-search-tree :key 0)))
    (find-or-insert -1 tree :insert-if-not-found nil))
  nil nil)

@ Here's a little utility routine taken from \csc{pcl}: |mapappend| is like
|mapcar| except that the results are appended together.

@l
(defun mapappend (fun &rest args)
  (if (some #'null args)
      ()
      (append (apply fun (mapcar #'car args))
              (apply #'mapappend fun (mapcar #'cdr args)))))

@ As mentioned above, named sections can be defined piecemeal, with the
code spread out over several sections in the \CLWEB\ source. We might think
of a named section as a sort of `virtual' section, which consists of a
name, the combined code parts of all of the physical sections with that
name, and the number of the first such section.

And that's what we store in the \csc{bst}: nodes that look like sections,
inasmuch as they have specialized |section-name|, |section-code|, and
|section-number| methods, but are not actually instances of the class
|section|. The commentary and code is stored in the |section| instances
that comprise a given named section: references to those sections are
stored in the |sections| slot.

The weaver uses the last slot, |used-by|, to generate cross-references.
It will be populated during reading with a list of all the sections that
reference this named section.

@l
(defclass named-section (binary-search-tree)
  ((key :accessor section-name :initarg :name)
   (sections :accessor named-section-sections :initform '())
   (used-by :accessor used-by :initform '())))

(defmethod named-section-sections :around ((section named-section))
  (sort (copy-list (call-next-method)) #'< :key #'section-number))

(defmethod section-code ((section named-section))
  (mapappend #'section-code (named-section-sections section)))

(defmethod section-number ((section named-section))
  (section-number (first (named-section-sections section))))

@t@l
(deftest named-section-number/code
  (let ((*sections* (make-array 5 :fill-pointer 0))
        (section (make-instance 'named-section)))
    (make-instance 'section) ; `limbo' section
    (loop for i from 1 to 3
          do (push (make-instance 'section :name "foo" :code (list i))
                   (named-section-sections section)))
    (values (section-code section)
            (section-number section)))
  (1 2 3)
  1)

@ Section names in the input file can be abbreviated by giving a prefix of
the full name followed by `$\ldots$': e.g., \.{@@<Frob...@@>} might refer
to the section named `Frob \(foo\) and tweak \(bar\)'.

Here's a little utility routine that makes working with such section names
easier. Given a name, it returns two values: true or false depending on
whether the name is a prefix or not, and the length of the non-`\.{...}'
segment of the name.

@l
(defun section-name-prefix-p (name)
  (let ((len (length name)))
    (if (string= name "..." :start1 (max (- len 3) 0) :end1 len)
        (values t (- len 3))
        (values nil len))))

@t@l
(deftest (section-name-prefix-p 1) (section-name-prefix-p "a") nil 1)
(deftest (section-name-prefix-p 2) (section-name-prefix-p "ab...") t 2)
(deftest (section-name-prefix-p 3) (section-name-prefix-p "abcd...") t 4)

@ Next we need some special comparison routines for section names that
might be abbreviations. We'll use these as the |:test| and |:predicate|
functions, respectively, for our \csc{bst}.

@l
(defun section-name-lessp (name1 name2)
  (let ((len1 (nth-value 1 (section-name-prefix-p name1)))
        (len2 (nth-value 1 (section-name-prefix-p name2))))
    (string-lessp name1 name2 :end1 len1 :end2 len2)))

(defun section-name-equal (name1 name2)
  (multiple-value-bind (prefix-1-p len1) (section-name-prefix-p name1)
    (multiple-value-bind (prefix-2-p len2) (section-name-prefix-p name2)
      (let ((end (min len1 len2)))
        (if (or prefix-1-p prefix-2-p)
            (string-equal name1 name2 :end1 end :end2 end)
            (string-equal name1 name2))))))

@t@l
(deftest (section-name-lessp 1) (section-name-lessp "b" "a") nil)
(deftest (section-name-lessp 2) (section-name-lessp "b..." "a...") nil)
(deftest (section-name-lessp 3) (section-name-lessp "ab" "a...") nil)

(deftest (section-name-equal 1) (section-name-equal "a" "b") nil)
(deftest (section-name-equal 2) (section-name-equal "a" "a") t)
(deftest (section-name-equal 3) (section-name-equal "a..." "ab") t)
(deftest (section-name-equal 4) (section-name-equal "a..." "ab...") t)

@ When we look up a named section, either the name used to perform the
lookup, the name for the section in the tree, or both might be a prefix
of the full section name.

@l
(defmethod find-or-insert (item (root named-section) &key
                           (predicate #'section-name-lessp)
                           (test #'section-name-equal)
                           (insert-if-not-found t))
  (multiple-value-bind (node present-p)
      (call-next-method item root
                        :predicate predicate
                        :test test
                        :insert-if-not-found insert-if-not-found)
    (if present-p
        (or @<Check for an ambiguous match, and raise an error in that case@>
            (values node t))
        (values node nil))))

@ @<Condition classes@>=
(define-condition ambiguous-prefix-error (error)
  ((prefix :reader ambiguous-prefix :initarg :prefix)
   (first-match :reader ambiguous-prefix-first-match :initarg :first-match)
   (alt-match :reader ambiguous-prefix-alt-match :initarg :alt-match))
  (:report
   (lambda (condition stream)
     (format stream "~@<Ambiguous prefix: <~A> matches both <~A> and <~A>~:@>"
             (ambiguous-prefix condition)
             (ambiguous-prefix-first-match condition)
             (ambiguous-prefix-alt-match condition)))))

@ If there is an ambiguity in a prefix match, the tree ordering guarantees
that it will occur in the sub-tree rooted at |node|.

@<Check for an ambiguous match...@>=
(dolist (child (list (left-child node) (right-child node)))
  (when child
    (multiple-value-bind (alt present-p)
        (call-next-method item child
                          :predicate predicate
                          :test test
                          :insert-if-not-found nil)
      (when present-p
        (restart-case
            (error 'ambiguous-prefix-error
                   :prefix item
                   :first-match (node-key node)
                   :alt-match (node-key alt))
          (use-first-match ()
            :report "Use the first match."
            (return (values node t)))
          (use-alt-match ()
            :report "Use alternate match."
            (return (values alt t))))))))

@ We store our named section tree in the global variable |*named-sections*|,
which is reset before each tangling or weaving. The reason this is global is
the same as the reason |*sections*| was: to allow incremental redefinition.

@<Global variables@>=
(defvar *named-sections* nil)

@ @<Initialize global variables@>=
(setq *named-sections* nil)

@ Section names are normalized by |squeeze|, which trims leading and
trailing whitespace and replaces all runs of one or more whitespace
characters with a single space.

@l
(defparameter *whitespace*
  #.(coerce '(#\Space #\Tab #\Newline #\Linefeed #\Page #\Return) 'string))

(defun whitespacep (char) (find char *whitespace* :test #'char=))

(defun squeeze (string)
  (loop with squeezing = nil
        for char across (string-trim *whitespace* string)
        if (not squeezing)
          if (whitespacep char)
            do (setq squeezing t) and collect #\Space into chars
          else
            collect char into chars
        else
          unless (whitespacep char)
            do (setq squeezing nil) and collect char into chars
        finally (return (coerce chars 'string))))

@t@l
(deftest (squeeze 1) (squeeze "abc") "abc")
(deftest (squeeze 2) (squeeze "ab c") "ab c")
(deftest (squeeze 3) (squeeze (format nil " a b ~C c " #\Tab)) "a b c")

@ The next routine is our primary interface to named sections: it looks up
a section by name in the tree, and creates a new one if no such section
exists.

@l
(defun find-section (name &aux (name (squeeze name)))
  (if (null *named-sections*)
      (values (setq *named-sections* (make-instance 'named-section :name name))@+
              nil)
      (multiple-value-bind (section present-p)
          (find-or-insert name *named-sections*)
        (when present-p
          @<Update the section name if the new one is better@>)
        (values section present-p))))

@ We only actually update the name of a section in two cases: if the new
name is not an abbreviation but the old one was, or if they are both
abbreviations but the new one is shorter. (We only need to compare against
the shortest available prefix, since we detect ambiguous matches.)

@<Update the section name...@>=
(multiple-value-bind (new-prefix-p new-len)
    (section-name-prefix-p name)
  (multiple-value-bind (old-prefix-p old-len)
      (section-name-prefix-p (section-name section))
    (when (or (and old-prefix-p (not new-prefix-p))
              (and old-prefix-p new-prefix-p (< new-len old-len)))
      (setf (section-name section) name))))

@t We'll use |*sample-named-sections*| whenever we need to test with some
named sections defined. The tests below don't depend on these sections
having code parts, but later tests will.

@l
(defvar *sample-named-sections*
  (let ((*sections* (make-array 10 :fill-pointer 0))
        (named-sections (make-instance 'named-section :name "baz")))
    (flet ((push-section (name code)
             (push (make-instance 'section :name name :code code)
                   (named-section-sections (find-or-insert name @+
                                                           named-sections)))))
      (push-section "baz" '(:baz))
      (push-section "foo" '(:foo))
      (push-section "bar" '(:bar))
      (push-section "qux" '(:qux)))
    named-sections))

(defun find-sample-section (name)
  (find-or-insert name *sample-named-sections* :insert-if-not-found nil))

(deftest find-named-section
  (section-name (find-sample-section "bar"))
  "bar")

(deftest find-section-by-prefix
  (section-name (find-sample-section "q..."))
  "qux")

(deftest find-section-by-ambiguous-prefix
  (section-name
   (handler-bind ((ambiguous-prefix-error
                   (lambda (condition)
                     (declare (ignore condition))
                     (invoke-restart 'use-alt-match))))
     (find-sample-section "b...")))
  "bar")

(deftest find-section
  (let ((*named-sections* *sample-named-sections*))
    (find-section (format nil " foo  bar ~C baz..." #\Tab))
    (section-name (find-section "foo...")))
  "foo")

@*Reading. We distinguish five distinct modes for reading. Limbo mode is
used for \TeX\ text that proceeds the first section in a file. \TeX\ mode
is used for reading the commentary that begins a section. Lisp mode is
used for reading the code part of a section; inner-Lisp mode is for
reading Lisp forms that are embedded within \TeX\ material. And finally,
restricted mode is used for reading material in section names and a few
other places.

We use seperate readtables for each mode, which are stored in |*readtables*|
and accessed via |readtable-for-mode|. We add an extra readtable with key
|nil| that stores a virgin copy of the standard readtable.

@<Global variables@>=
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *modes* '(:limbo :TeX :lisp :inner-lisp :restricted)))
(deftype mode () `(member ,@*modes*))

(defvar *readtables*
  (loop for mode in (cons nil *modes*)
        collect (cons mode (copy-readtable nil))))

@ @l
(defun readtable-for-mode (mode)
  (declare (type (or mode null) mode))
  (cdr (assoc mode *readtables*)))

@t@l
(deftest (readtable-for-mode 1) (readtablep (readtable-for-mode :tex)) t)
(deftest (readtable-for-mode 2) (readtablep (readtable-for-mode nil)) t)
(deftest (readtable-for-mode 3)
  (eql (readtable-for-mode :tex) (readtable-for-mode :lisp))
  nil)

@ The following macro is just a bit of syntactic sugar for executing the
given forms with |*readtable*| bound appropriately for the given mode.

@l
(defmacro with-mode (mode &body body)
  `(let ((*readtable* (readtable-for-mode ,mode)))
     ,@body))

@t@l
(deftest with-mode
  (loop for (mode . readtable) in *readtables*
        always (with-mode mode (eql *readtable* readtable)))
  t)

@ Sometimes we'll have to detect and report errors during reading. This
condition class and associated signaling function allow |format|-style
error reporting.

@<Condition classes@>=
(define-condition simple-reader-error (reader-error simple-condition) ()
  (:report (lambda (condition stream)
             (format stream "~S on ~S:~%~?"
                     condition (stream-error-stream condition)
                     (simple-condition-format-control condition)
                     (simple-condition-format-arguments condition)))))

(defun simple-reader-error (stream control &rest args)
  (error 'simple-reader-error
         :stream stream
         :format-control control
         :format-arguments args))

@ We frequently need an object to use as the |eof-value| argument to
|read|. It need not be a symbol; it need not even be an atom.

@<Global variables@>=
(defvar *eof* (make-symbol "EOF"))

@ @l
(defun eof-p (x) (eq x *eof*))
(deftype eof () '(satisfies eof-p))

@t@l
(deftest eof-p (eof-p (read-from-string "" nil *eof*)) t)
(deftest eof-type (typep (read-from-string "" nil *eof*) 'eof) t)

@ We'll occasionally need to know if a given character terminates a token
or not. This function answers that question, but only approximately---if
the user has frobbed the current readtable and set non-standard characters
to whitespace syntax, {\it this routine will not yield the correct
result}. There's unfortunately nothing that we can do about it portably,
since there's no way of determining the syntax of a character or of
obtaining a list of all the characters with a given syntax.

@l
(defun token-delimiter-p (char)
  (or (whitespacep char)
      (multiple-value-bind (function non-terminating-p)
          (get-macro-character char)
        (and function (not non-terminating-p)))))

@t@l
(deftest (token-delimiter-p 1) (not (token-delimiter-p #\Space)) nil)
(deftest (token-delimiter-p 2) (not (token-delimiter-p #\))) nil)

@ We want the weaver to output properly indented code, but it's basically
impossible to automatically indent Common Lisp code without a complete
static analysis. And so we don't try. What we do instead is assume that the
input is indented correctly, and try to approximate that on output; we call
this process {\it indentation tracking\/}.

The way we do this is to record the the column number, or {\it character
position}, of every Lisp form in the input, and use those positions to
reconstruct the original indentation.

We'll define a {\it charpos stream\/} as an object that tracks the
character position of an underlying stream. Note that these aren't
instances of |cl:stream| (and can't be, without relying on an extension to
Common Lisp like Gray streams). But they contain a standard composite
stream we'll call a {\it proxy stream} which is hooked up to the underlying
stream whose position they're tracking, and it's these proxy streams that
we'll pass around, so that the standard stream functions will all work.

@l
(defclass charpos-stream ()
  ((charpos :initarg :charpos)
   (proxy-stream :accessor charpos-proxy-stream :initarg :proxy))
  (:default-initargs :charpos 0))

@ The \csc{gf} |charpos| returns the current character position of a charpos
stream. It relies on the last calculated character position (stored in the
|charpos| slot) and a buffer that stores the characters input or output
since the last call to |charpos|, retrieved with |get-charpos-stream-buffer|.

@l
(defgeneric get-charpos-stream-buffer (stream))

(defgeneric charpos (stream))
(defmethod charpos ((stream charpos-stream))
  (let* ((buffer (get-charpos-stream-buffer stream))
         (len (length buffer))
         (newline (position #\Newline buffer :test #'char= :from-end t)))
    (if newline
        (setf (slot-value stream 'charpos) (- len 1 newline))
        (incf (slot-value stream 'charpos) len))))

@ For tracking the character position of an input stream, our proxy stream
will be an echo stream that takes input from the underlying stream and sends
its output to a string stream, which we'll use as our buffer.

@l
(defclass charpos-input-stream (charpos-stream) ())

(defmethod shared-initialize :around ((instance charpos-input-stream) slot-names
                                      &rest initargs &key stream)
  (apply #'call-next-method instance slot-names
         (list* :proxy (make-echo-stream
                        stream
                        (make-string-output-stream
                         :element-type (stream-element-type stream)))
                initargs)))

(defmethod get-charpos-stream-buffer ((stream charpos-input-stream))
  (get-output-stream-string
   (echo-stream-output-stream (charpos-proxy-stream stream))))

@ For the output stream case, our proxy stream is a broadcast stream to the
given stream and a fresh string stream, again used as a buffer.

@l
(defclass charpos-output-stream (charpos-stream) ())

(defmethod shared-initialize :around ((instance charpos-output-stream) slot-names
                                      &rest initargs &key stream)
  (apply #'call-next-method instance slot-names
         (list* :proxy (make-broadcast-stream
                        (make-string-output-stream
                         :element-type (stream-element-type stream))
                        stream)
                initargs)))

(defmethod get-charpos-stream-buffer ((stream charpos-output-stream))
  (get-output-stream-string
   (first (broadcast-stream-streams (charpos-proxy-stream stream)))))

@ Because we'll be passing around the proxy streams, we need to manually
maintain a mapping between them and their associated instances of
|charpos-stream|.

@<Global variables@>=
(defvar *charpos-streams* (make-hash-table :test #'eq))

@ @l
(defmethod initialize-instance :after ((instance charpos-stream) @+
                                       &rest initargs &key)
  (declare (ignore initargs))
  (setf (gethash (charpos-proxy-stream instance) *charpos-streams*) instance))

@ The top-level interface to the charpos streams are the following two
functions: |stream-charpos| retrieves the character position of the stream
for which |stream| is a proxy, and |release-charpos-stream| deletes the
reference to the stream maintained by the associated |charpos-stream|
instance.

@l
(defun stream-charpos (stream)
  (charpos (or (gethash stream *charpos-streams*)
               (error "Not tracking charpos for ~S" stream))))

(defun release-charpos-stream (stream)
  (multiple-value-bind (charpos-stream present-p)
      (gethash stream *charpos-streams*)
    (cond (present-p
           (setf (charpos-proxy-stream charpos-stream) nil) ; release stream
           (remhash stream *charpos-streams*))
          (t (warn "Not tracking charpos for ~S" stream)))))

@ Here are a few convenience methods for creating charpos streams. The
|input-stream| and |output-stream| arguments are stream designators.

@l
(defun make-charpos-input-stream (input-stream &key (charpos 0))
  (make-instance 'charpos-input-stream
                 :stream (case input-stream
                           ((t) *terminal-io*)
                           ((nil) *standard-input*)
                           (otherwise input-stream))
                 :charpos charpos))

(defun make-charpos-output-stream (output-stream &key (charpos 0))
  (make-instance 'charpos-output-stream
                 :stream (case output-stream
                           ((t) *terminal-io*)
                           ((nil) *standard-output*)
                           (otherwise output-stream))
                 :charpos charpos))

@ And finally, here are a couple of macros that make using them easy and
trouble-free. They execute |body| in a lexical environment in which |var|
is bound to a proxy stream the tracks the character position for |stream|.

@l
(defmacro with-charpos-input-stream ((var stream &key (charpos 0)) &body body)
  `(let ((,var (charpos-proxy-stream @+
                (make-charpos-input-stream ,stream :charpos ,charpos))))
     (unwind-protect (progn ,@body)
       (release-charpos-stream ,var))))

(defmacro with-charpos-output-stream ((var stream &key (charpos 0)) &body body)
  `(let ((,var (charpos-proxy-stream @+
                (make-charpos-output-stream ,stream :charpos ,charpos))))
     (unwind-protect (progn ,@body)
       (release-charpos-stream ,var))))

@t@l
(deftest charpos-input-stream
  (with-charpos-input-stream (s (make-string-input-stream
                                 (format nil "012~%abc")))
    (values (stream-charpos s)
            (read-line s)
            (stream-charpos s)
            (read-char s)
            (read-char s)
            (read-char s)
            (stream-charpos s)))
  0 "012" 0 #\a #\b #\c 3)

(deftest charpos-output-stream
  (let ((string-stream (make-string-output-stream)))
    (with-charpos-output-stream (s string-stream)
      (values (stream-charpos s)
              (progn (write-string "012" s) (stream-charpos s))
              (progn (write-char #\Newline s) (stream-charpos s))
              (progn (write-string "abc" s) (stream-charpos s))
              (get-output-stream-string string-stream))))
  0 3 0 3 #.(format nil "012~%abc"))

@ Sometimes we'll want to look more than one character ahead in a stream.
This macro lets us do so, after a fashion: it executes |body| in a lexical
environment where |var| is bound to a stream whose input comes from
|stream| and |rewind| is a local function that `rewinds' that stream to its
state prior to any reads executed in the body.

@l
(defmacro with-rewind-stream ((var stream &optional (rewind 'rewind))
                              &body body &aux (out (gensym)))
  `(with-open-stream (,out (make-string-output-stream))
     (with-open-stream (,var (make-echo-stream ,stream ,out))
       (flet ((,rewind ()
                (setq ,var (make-concatenated-stream
                            (make-string-input-stream @+
                             (get-output-stream-string ,out))
                            ,var))))
         ,@body))))

@t@l
(deftest rewind-stream
  (with-rewind-stream (s (make-string-input-stream "abcdef"))
    (values (read-char s)
            (read-char s)
            (read-char s)
            (progn (rewind) (read-char s))
            (progn (rewind) (read-line s))))
  #\a #\b #\c #\a "bcdef")

@ And sometimes, we'll want to call |read| on a stream, and keep a copy of
the characters that |read| actually scans. This macro reads from |stream|,
then executes the |body| forms with |values| bound to a list of the values
returned by |read|, and |echoed| bound to a variable containing the
characters so consumed. If |prefix| is supplied, it should be a string that
will be concatenated onto the front of |stream| prior to reading.

@l
(defmacro read-with-echo ((stream values echoed &key prefix) &body body &aux
                          (out (gensym)) (echo (gensym)) (rewind (gensym))
                          (raw-output (gensym)) (length (gensym)))
  `(with-open-stream (,out (make-string-output-stream))
     (with-open-stream (,echo (make-echo-stream ,stream ,out))
       (with-open-stream (,rewind (make-concatenated-stream
                                   ,@(when prefix
                                       `((make-string-input-stream ,prefix)))
                                   ,echo))
         (let* ((,values (multiple-value-list @+
                          (read-preserving-whitespace ,rewind)))
                (,raw-output (get-output-stream-string ,out))
                (,length (length ,raw-output))
                (,echoed (subseq ,raw-output
                                 0
                                 (if (or (eof-p @+
                                          (peek-char nil ,rewind nil *eof*))
                                         (token-delimiter-p @+
                                          (elt ,raw-output (1- ,length))))
                                     ,length
                                     (1- ,length)))))
           (declare (ignorable ,values ,echoed))
           ,@body)))))

@t@l
(deftest read-with-echo
  (read-with-echo ((make-string-input-stream ":foo :bar") values chars)
    (values values chars))
  (:foo) ":foo ")

(deftest read-with-echo-to-eof
  (read-with-echo ((make-string-input-stream ":foo") values chars)
    (values values chars))
  (:foo) ":foo")

@ Next, we define a class of objects called {\it markers\/} that denote
abstract objects in source code. Some of these objects, such as newlines
and comments, are ones that would ordinarily be ignored by the reader.
Others, such as \.{()} and~\.{'}, are indistinguishable after reading from
other, semantically equivalent objects (here, |nil| and |quote|), but we
want to preserve the distinction in the output. In fact, nearly every
standard macro character in Common Lisp is `lossy', in the sense that the
text of the original source code can not be reliably recovered from the
object returned by |read|.

But during weaving, we want to more closely approximate the original source
code than would be possible using the standard reader. Markers are our
solution to this problem: we define reader macro functions for all of the
standard macro characters that return markers that let us reconstruct, to
varying degrees of accuracy, what was originally given in the source.

If a marker is {\it bound}---i.e., if |marker-boundp| returns non-nil when
called with it as an argument---then the tangler will call |marker-value|
to obtain the associated value. (The weaver will never ask for a marker's
value). Otherwise, the marker will be silently dropped from its containing
form; this is used, e.g., for newlines and comments. The value need not be
stored in the |value| slot, but often is.

@l
(defclass marker ()
  ((value :reader marker-value :initarg :value)))
(defun markerp (x) (typep x 'marker))

(defgeneric marker-boundp (marker))
(defmethod marker-boundp ((marker marker))
  (slot-boundp marker 'value))

@ We'll provide |print-object| methods for all of our marker classes. These
methods are distinct from the pretty-printing routines used by the weaver,
and usually less precise, in that they don't try to approximate the original
source form. The idea of these methods is to produce a printed representation
of an object that is semantically equivalent to the one originally specified.

We'll also define also a global variable, |*print-marker*|, that controls
the way markers are printed. If it is true (as it is by default), then
markers will be printed as just described. If it is false, markers are
printed using the unreadable `\.\#\<' notation. This can be useful for
debugging some of the reader routines, but might break others, so be
careful. Routines that depend on this being set should explicitly bind it.

@<Global variables@>=
(defvar *print-marker* t)

@ The simple method defined here suffices for many marker types: it simply
prints the marker's value if it is bound. Markers that require specialized
printing will override this method.

@l
(defmethod print-object ((obj marker) stream)
  (if *print-marker*
      (when (marker-boundp obj)
        (write (marker-value obj) :stream stream))
      (print-unreadable-object (obj stream :type t :identity t)
        (when (marker-boundp obj)
          (princ (marker-value obj) stream)))))

@t@l
(deftest print-marker
  (let ((*print-marker* t))
    (format nil "~A" (make-instance 'marker :value ':foo)))
  "FOO")

(deftest print-marker-unreadably
  (let ((*print-marker* nil)
        (*print-readably* t))
    (handler-case (format nil "~W" (make-instance 'marker :value ':foo))
      (print-not-readable (condition)
        (marker-value (print-not-readable-object condition)))))
  :foo)

@ A few of the markers behave differently when tangling for the purposes
of evaluation (e.g., within a call to |load-web|) than when writing out a
tangled Lisp source file. We need this distinction only for read-time
evaluated constructs, such as \.{\#.} and~\.{\#+}/\.{\#-}.

@<Global variables@>=
(defvar *evaluating* nil)

@ Our first marker is for newlines, which we preserve for the purposes of
indentation. They are represented in code forms by an unbound marker, so
the tangler will ignore them.

Note that we don't set a macro character for |#\Newline| in inner-Lisp mode,
since indentation is completely ignored there.

@l
(defclass newline-marker (marker)
  ((indentation :accessor indentation :initform nil)))
(defun newlinep (obj) (typep obj 'newline-marker))

(set-macro-character #\Newline
                     (lambda (stream char)
                       (declare (ignore stream char))
                       (make-instance 'newline-marker))
                     nil (readtable-for-mode :lisp))

@t@l
(deftest read-newline
  (newlinep (with-input-from-string (s (format nil "~%"))
              (with-mode :lisp (read s))))
  t)

@ The rest of the reader macro functions for standard macro characters are
defined in the order given in section~2.4 of the \csc{ansi} Common Lisp
standard. We override all of the standard macro characters except |#\)|
and~|#\"| (the former because the standard reader macro function just
signals an error, which is fine, and the latter because we don't need
markers for strings).

@ {\it Left-Parenthesis.} We have two different kinds of markers for lists.
The first is one for empty lists, so that we can maintain a distinction
that the standard Lisp reader does not: between the empty list and |nil|.
The second, for non-empty lists, stores not just the elements of the list,
but their character positions as well; this is what allows us to do our
indentation tracking.

Note that we bind our empty-list marker to the value |'()| so that it's
preserved during tangling.

@l
(defclass empty-list-marker (marker) () (:default-initargs :value '()))
(defvar *empty-list* (make-instance 'empty-list-marker))

(defclass list-marker (marker)
  ((length :accessor list-marker-length :initarg :length)
   (list :accessor list-marker-list :initarg :list)
   (charpos :accessor list-marker-charpos :initarg :charpos)))
(defun list-marker-p (obj) (typep obj 'list-marker))

(defclass consing-dot-marker (marker) ())
(defvar *consing-dot* (make-instance 'consing-dot-marker))

(defmethod marker-boundp ((marker list-marker)) t)
(defmethod marker-value ((marker list-marker))
  (do* ((list (list nil))
        (tail list)
        (marker-list (list-marker-list marker) (cdr marker-list))
        (x (car marker-list) (car marker-list)))
       ((endp marker-list) (cdr list))
    (cond ((eq x *consing-dot*)
           (rplacd tail @<Find the tail...@>)
           (return (cdr list)))
          ((markerp x)
           (when (marker-boundp x)
             (let ((obj (list x)))
               (rplacd tail obj)
               (setq tail obj))))
          (t (let ((obj (list x)))
               (rplacd tail obj)
               (setq tail obj))))))

@ There might be more than one object in a list marker following a consing
dot, because of unbound markers (e.g., newlines and comments). So we just
use the first bound marker or non-marker object that we find.

@<Find the tail of the list marker@>=
(dolist (x marker-list (error "Nothing after . in list"))
  (when (or (not (markerp x))
            (and (markerp x)
                 (marker-boundp x)))
    (return x)))

@ We don't use |list-marker|s at all in inner-Lisp mode (since we don't do
indentation tracking there), but we still want markers for the empty list.
The function |make-list-reader| returns a closure that peeks ahead in the
given stream looking for a closing parenthesis, and either returns an
empty-list marker or invokes a full list-reading function, which is stored
in the variable |next|. For inner-Lisp mode, that function is the standard
reader macro function for |#\(|.

@l
(defun make-list-reader (next)
  (lambda (stream char)
    (if (char= (peek-char t stream t nil t) #\) )
        (progn (read-char stream t nil t) *empty-list*)
        (funcall next stream char))))

(set-macro-character #\( (make-list-reader (get-macro-character #\( nil))
                     nil (readtable-for-mode :inner-lisp))

@ In Lisp mode, we need a full list reader that records character positions
of the list elements. This would be perfectly straightforward if not for the
consing dot.

@l
(defun list-reader (stream char)
  (declare (ignore char))
  (loop with list = '()
        with charpos-list = '()
        for n from 0
        for first-char = (peek-char t stream t nil t)
        as charpos = (stream-charpos stream)
        until (char= first-char #\) )
        if (char= first-char #\.)
          do @<Read the next token from |stream|, which might be a consing dot@>
        else do (push (read stream t nil t) list)
                (push charpos charpos-list)
        finally (read-char stream t nil t)
                (return (make-instance 'list-marker
                                       :length n
                                       :list (nreverse list)
                                       :charpos (nreverse charpos-list)))))

(set-macro-character #\( (make-list-reader #'list-reader)
                     nil (readtable-for-mode :lisp))

@ @<Read the next token from |stream|...@>=
(with-rewind-stream (stream stream)
  (read-char stream t) ; consume dot
  (let ((next-char (read-char stream t)))
    (cond ((token-delimiter-p next-char)
           (unless (or list *read-suppress*)
             (simple-reader-error stream "Nothing appears before . in list."))
           (push *consing-dot* list)
           (push charpos charpos-list))
          (t (rewind)
             (push (read stream t nil t) list)
             (push charpos charpos-list)))))

@t When we're testing the reader functions, we'll often want to read from
a string-stream that tracks character positions.

@l
(defmacro read-from-string-with-charpos (string &optional
                                         (eof-error-p t)
                                         (eof-value nil) &key
                                         (preserve-whitespace nil) &aux
                                         (string-stream (gensym))
                                         (charpos-stream (gensym)))
  `(with-open-stream (,string-stream (make-string-input-stream ,string))
     (with-charpos-input-stream (,charpos-stream ,string-stream)
       (if ,preserve-whitespace
           (read-preserving-whitespace ,charpos-stream ,eof-error-p ,eof-value)
           (read ,charpos-stream ,eof-error-p ,eof-value)))))

@t In fact, most of the reader tests will involve reading a single form in
Lisp mode.

@l
(defun read-form-from-string (string &key (mode :lisp))
  (with-mode mode
    (read-from-string-with-charpos string)))

@t@l
(deftest read-empty-list-inner-lisp
  (typep (read-form-from-string "()" :mode :inner-lisp) 'empty-list-marker)
  t)

(deftest read-empty-list
  (typep (read-form-from-string "()") 'empty-list-marker)
  t)

(deftest read-list-inner-lisp
  (listp (read-form-from-string "(:a :b :c)" :mode :inner-lisp))
  t)

(deftest read-list
  (marker-value (read-form-from-string "(:a :b :c)"))
  (:a :b :c))

(deftest read-dotted-list
  (marker-value (read-form-from-string "(:a :b . :c)"))
  (:a :b . :c))

(deftest list-marker-charpos
  (list-marker-charpos (read-form-from-string "(1 2 3)"))
  (1 3 5))

@ {\it Single-Quote.} We want to distinguish between a form quoted with
a single-quote and one quoted (for whatever reason) with |quote|, another
distinction ignored by the standard Lisp reader. We'll use this marker
class for \.{\#'}, too, which is why it's a little more general than one
might think is needed.

@l
(defclass quote-marker (marker)
  ((quote :reader quote-marker-quote :initarg :quote)
   (form :reader quoted-form :initarg :form)))

(defmethod marker-boundp ((marker quote-marker)) t)
(defmethod marker-value ((marker quote-marker))
  (list (quote-marker-quote marker) (quoted-form marker)))

(defun single-quote-reader (stream char)
  (declare (ignore char))
  (make-instance 'quote-marker :quote 'quote :form (read stream t nil t)))

(dolist (mode '(:lisp :inner-lisp))
  (set-macro-character #\' #'single-quote-reader nil (readtable-for-mode mode)))

@t@l
(deftest read-quoted-form
  (let ((marker (read-form-from-string "':foo")))
    (values (quoted-form marker)
            (marker-value marker)))
  :foo
  (quote :foo))

@ {\it Semicolon.} Comments in Lisp code also need to be preserved for
output during weaving. Comment markers are always unbound, and are
therefore stripped during tangling.

@l
(defclass comment-marker (marker)
  ((text :reader comment-text :initarg :text)))

@ To read a comment, we accumulate all of the characters starting with the
semicolon and ending just before the next newline, which we leave for the
newline reader to pick up.

@l
(defun comment-reader (stream char)
  (make-instance 'comment-marker
                 :text @<Read characters up to, but not including,
                         the next newline@>))

(set-macro-character #\; #'comment-reader nil (readtable-for-mode :lisp))

@ @<Read characters up to...@>=
(with-output-to-string (s)
  (write-char char s) ; include the opening |#\;|
  (do ()
      ((char= (peek-char nil stream nil #\Newline t) #\Newline))
    (write-char (read-char stream t nil t) s)))

@t@l
(deftest read-comment
  (let ((marker (read-form-from-string "; foo")))
    (values (comment-text marker)
            (marker-boundp marker)))
  "; foo"
  nil)

@ {\it Backquote\/} is hairy, and so we use a kludge to avoid implementing
the whole thing. Our reader macro functions for |#\`| and |#\,| do the
absolute minimum amount of processing necessary to be able to reconstruct
the forms that were read. When the tangler asks for the |marker-value| of a
backquote marker, we reconstruct the source form using the printer, and
read it back in using the standard readtable. It's a sleazy trick, but it
works. (It's also the reason we need |print-object| methods for all these
markers.)

Of course, this trick assumes read-print equivalence, but that's not
unreasonable, since without it the file tangler won't work anyway.

@l
(defclass backquote-marker (marker)
  ((form :reader backq-form :initarg :form)))

(defmethod marker-boundp ((marker backquote-marker)) t)
(defmethod marker-value ((marker backquote-marker))
  (let ((*print-pretty* nil)
        (*print-readably* t)
        (*print-marker* t)
        (*readtable* (readtable-for-mode nil)))
    (values (read-from-string (prin1-to-string marker)))))

(defmethod print-object ((obj backquote-marker) stream)
  (if *print-marker*
      (format stream "`~W" (backq-form obj))
      (print-unreadable-object (obj stream :type t :identity t))))

(defun backquote-reader (stream char)
  (declare (ignore char))
  (make-instance 'backquote-marker :form (read stream t nil t)))

(dolist (mode '(:lisp :inner-lisp))
  (set-macro-character #\` #'backquote-reader nil (readtable-for-mode mode)))

@t@l
(deftest read-backquote
  (let ((marker (read-form-from-string "`(:a :b :c)")))
    (and (typep marker 'backquote-marker)
         (marker-value marker)))
  #.(read-from-string "`(:a :b :c)"))

@ {\it Comma\/} is really just part of the backquote-syntax, and so we're
after the same goal as above: reconstructing just enough of the original
source so that the reader can do what it would have done had we not been
here in the first place.

Note that comma markers are bound, but self-evaluating: they need to be
printed and re-read as part of a backquote form to retrieve their actual
value.

@l
(defclass comma-marker (marker)
  ((form :reader comma-form :initarg :form)
   (modifier :reader comma-modifier :initarg :modifier))
  (:default-initargs :modifier nil))

(defmethod marker-boundp ((marker comma-marker)) t)
(defmethod marker-value ((marker comma-marker)) marker)

(defmethod print-object ((obj comma-marker) stream)
  (if *print-marker*
      (format stream ",~@[~C~]~W" (comma-modifier obj) (comma-form obj))
      (print-unreadable-object (obj stream :type t :identity t))))

(defun comma-reader (stream char)
  (declare (ignore char))
  (case (peek-char nil stream t nil t)
    ((#\@ #\.) (make-instance 'comma-marker
                              :modifier (read-char stream)
                              :form (read stream t nil t)))
    (t (make-instance 'comma-marker :form (read stream t nil t)))))

(dolist (mode '(:lisp :inner-lisp))
  (set-macro-character #\, #'comma-reader nil (readtable-for-mode mode)))

@t@l
(deftest read-comma
  (eval (marker-value (read-form-from-string "`(:a ,@'(:b :c) :d)")))
  (:a :b :c :d))

@ {\it Sharpsign\/} is the all-purpose dumping ground for Common Lisp
reader macros. Because it's a dispatching macro character, we have to
handle each sub-char individually, and unfortunately we need to override
most of them. We'll handle them in the order given in section~2.4.8
of the CL standard.

@ Sharpsign single-quote is just like single-quote, except that the form is
`quoted' with |function| instead of |quote|.

@l
(defclass function-marker (quote-marker) ())

(defun sharpsign-quote-reader (stream sub-char arg)
  (declare (ignore sub-char arg))
  (make-instance 'function-marker :quote 'function :form (read stream t nil t)))

(dolist (mode '(:lisp :inner-lisp))
  (set-dispatch-macro-character #\# #\' #'sharpsign-quote-reader @+
                                (readtable-for-mode mode)))

@t@l
(deftest read-function
  (let ((marker (read-form-from-string "#'identity")))
    (values (quoted-form marker)
            (marker-value marker)))
  identity
  #'identity)

@ Sharpsign left-parenthesis creates |simple-vector|s. The feature that we
care about preserving is the length specification and consequent possible
abbreviation.

@l
(defclass simple-vector-marker (marker)
  ((length :initarg :length)
   (elements :initarg :elements)
   (element-type :initarg :element-type))
  (:default-initargs :element-type t))

(defmethod marker-boundp ((marker simple-vector-marker)) t)
(defmethod marker-value ((marker simple-vector-marker))
  (with-slots (elements element-type) marker
    (if (slot-boundp marker 'length)
        (with-slots (length) marker
          (let ((supplied-length (length elements)))
            (fill (replace (make-array length :element-type element-type) @+
                           elements)
                  (elt elements (1- supplied-length))
                  :start supplied-length)))
        (coerce elements `(vector ,element-type)))))

;; Adapted from SBCL's |sharp-left-paren|.
(defun simple-vector-reader (stream sub-char arg)
  (declare (ignore sub-char))
  (let* ((list (read-delimited-list #\) stream t))
         (length (handler-case (length list)
                   (type-error (error)
                     (declare (ignore error))
                     (simple-reader-error @+
                      stream "improper list in #(): ~S" list)))))
    (unless *read-suppress*
      (if arg
          (if (> length arg)
              (simple-reader-error @+
               stream "vector longer than specified length: #~S~S" arg list)
              (make-instance 'simple-vector-marker :length arg :elements list))
          (make-instance 'simple-vector-marker :elements list)))))

(dolist (mode '(:lisp :inner-lisp))
  (set-dispatch-macro-character #\# #\( #'simple-vector-reader @+
                                (readtable-for-mode mode)))

@t@l
(deftest read-simple-vector
  (marker-value (read-form-from-string "#5(:a :b :c)"))
  #(:a :b :c :c :c))

@ Sharpsign asterisk is similar, but the token following the asterisk must
be composed entirely of \.{0}s and \.{1}s, from which a |simple-bit-vector|
is constructed. It supports the same kind of abbreviation that \.{\#()}
does.

Note the use of the word `token' above. By defining \.{\#*} in terms of the
{\it token\/} following the \.{*}, the authors of the standard have made it
very, very difficult for a portable program to emulate the specified behavior,
since only the built-in reader knows how to tokenize for the current
readtable. What we do is resort to a dirty trick: we set up an echo stream,
use the standard reader to parse the bit vector, then build our marker from
the echoed characters.

@l
(defclass bit-vector-marker (simple-vector-marker) ()
  (:default-initargs :element-type 'bit))

(defun simple-bit-vector-reader (stream sub-char arg)
  (declare (ignore sub-char))
  (let ((*readtable* (readtable-for-mode nil)))
    (read-with-echo (stream values bits :prefix (format nil "#~@[~D~]*" arg))
      (apply #'make-instance 'bit-vector-marker
             :elements @<Build a bit vector...@>
             (if arg (list :length arg))))))

(dolist (mode '(:lisp :inner-lisp))
  (set-dispatch-macro-character #\# #\* #'simple-bit-vector-reader @+
                                (readtable-for-mode mode)))


@ The string |bits| now contains the `0' and~`1' characters that make up
the bit vector. But it might also contain the delimiter that terminates the
token, so we have to be careful.

@<Build a bit vector from the characters in |bits|@>=
(map 'bit-vector
     (lambda (c) (ecase c (#\0 0) (#\1 1)))
     (subseq bits 0 (let ((n (length bits)))
                      (case (elt bits (1- n)) ((#\0 #\1) n) (t (1- n))))))

@t@l
(deftest read-bit-vector
  (marker-value (read-form-from-string "#5*101"))
  #5*101)

@ Sharpsign dot permits read-time evaluation. Ordinarily, of course, the
form evaluated is lost, as only the result of the evaluation is returned.
We want to preserve the form for both weaving and tangling to a file. But
we also want to return the evaluated form as the |marker-value| when we're
tangling for evaluation. So if we're not evaluating, we return a special
`pseudo-marker' with a specialized |print-object| method. This gives us an
appropriate value in all three situations: during weaving, we have just
another marker; when tangling for evaluation, we get the read-time-evaluated
value; and in a tangled source file, we get a \.{\#.} form.

@l
(defclass read-time-eval ()
  ((form :reader read-time-eval-form :initarg :form)))

(defmethod print-object ((obj read-time-eval) stream)
  (if *print-marker*
      (format stream "#.~W" (read-time-eval-form obj))
      (print-unreadable-object (obj stream :type t :identity t))))

(defclass read-time-eval-marker (read-time-eval marker) ())

(defmethod marker-boundp ((marker read-time-eval-marker)) t)
(defmethod marker-value ((marker read-time-eval-marker))
  (if *evaluating*
      (call-next-method)
      (make-instance 'read-time-eval :form (read-time-eval-form marker))))

(defun sharpsign-dot-reader (stream sub-char arg)
  (declare (ignore sub-char arg))
  (let* ((*readtable* (if *evaluating* (readtable-for-mode nil) *readtable*))
         (form (read stream t nil t)))
    (unless *read-suppress*
      (unless *read-eval*
        (simple-reader-error stream "can't read #. while *READ-EVAL* is NIL"))
      (make-instance 'read-time-eval-marker :form form :value (eval form)))))

(dolist (mode '(:lisp :inner-lisp))
  (set-dispatch-macro-character #\# #\. #'sharpsign-dot-reader @+
                                (readtable-for-mode mode)))

@t@l
(deftest (read-time-eval 1)
  (let* ((*read-eval* t)
         (*evaluating* nil)
         (*print-marker* t))
    (prin1-to-string (marker-value (read-form-from-string "#.(+ 1 1)"))))
  "#.(+ 1 1)")

(deftest (read-time-eval 2)
  (let* ((*read-eval* t)
         (*evaluating* t))
    (marker-value (read-form-from-string "#.(+ 1 1)")))
  2)

@ Sharpsign B, O, X, and~R all represent rational numbers in a specific
radix, but the radix is discarded by the standard reader, which just
returns the number. We use the standard reader macro function for getting
the actual value, and store the radix in our marker.

@l
(defclass radix-marker (marker)
  ((base :reader radix-marker-base :initarg :base)))

(defparameter *radix-prefix-alist* @+
  '((#\B . 2) (#\O . 8) (#\X . 16) (#\R . nil)))

(defun radix-reader (stream sub-char arg)
  (make-instance 'radix-marker
                 :base (or (cdr (assoc (char-upcase sub-char) @+
                                       *radix-prefix-alist*)) @+
                           arg)
                 :value @<Call the standard reader macro fun...@>))

(dolist (mode '(:lisp :inner-lisp))
  (dolist (sub-char '(#\B #\b #\O #\o #\X #\x #\R #\r))
    (set-dispatch-macro-character #\# sub-char #'radix-reader @+
                                  (readtable-for-mode mode))))

@ @<Call the standard reader macro function for \.{\#\metasyn{|sub-char|}}@>=
(funcall (get-dispatch-macro-character #\# sub-char (readtable-for-mode nil))
         stream sub-char arg)

@t@l
(deftest (read-radix 1)
  (let ((marker (read-form-from-string "#B1011")))
    (values (radix-marker-base marker)
            (marker-value marker)))
  2
  11)

(deftest (read-radix 2)
  (let ((marker (read-form-from-string "#14R11")))
    (values (radix-marker-base marker)
            (marker-value marker)))
  14
  15)

@ Sharpsign~S requires determining the standard constructor function of the
structure type named, which we simply can't do portably. So we use the same
trick we used for backquote above: we cache the form as given, then dump it
out to a string and let the standard reader parse it when we need the value.

@l
(defclass structure-marker (marker)
  ((form :reader structure-marker-form :initarg :form)))

(defmethod marker-boundp ((marker structure-marker)) t)
(defmethod marker-value ((marker structure-marker))
  (let ((*print-pretty* nil)
        (*print-readably* t)
        (*print-marker* t)
        (*readtable* (readtable-for-mode nil)))
    (values (read-from-string (prin1-to-string marker)))))

(defmethod print-object ((obj structure-marker) stream)
  (if *print-marker*
      (format stream "#S~W" (structure-marker-form obj))
      (print-unreadable-object (obj stream :type t :identity t))))

(defun structure-reader (stream sub-char arg)
  (declare (ignore sub-char arg))
  (make-instance 'structure-marker :form (read stream t nil t)))

(dolist (mode '(:lisp :inner-lisp))
  (set-dispatch-macro-character #\# #\S #'structure-reader @+
                                (readtable-for-mode mode)))

@ Sharpsign + and~-- provide read-time conditionalization based on
feature expressions, described in section~24.1.2 of the CL standard.
This routine, adapted from SBCL, interprets such an expression.

@l
(defun featurep (x)
  (etypecase x
    (cons
     (case (car x)
       ((:not not)
        (cond
          ((cddr x) @+
           (error "too many subexpressions in feature expression: ~S" x))
          ((null (cdr x)) @+
           (error "too few subexpressions in feature expression: ~S" x))
          (t (not (featurep (cadr x))))))
       ((:and and) (every #'featurep (cdr x)))
       ((:or or) (some #'featurep (cdr x)))
       (t
        (error "unknown operator in feature expression: ~S." x))))
    (symbol (not (null (member x *features* :test #'eq))))))

@t@l
(deftest featurep
  (let ((*features* '(:a :b)))
    (featurep '(:and :a (:or :c :b) (:not :d))))
  t)

@ For sharpsign +/--, we use the same sort of trick we used for \.{\#.}
above: we have a marker that returns the appropriate value when tangling for
evaluation, but returns a `pseudo-marker' when tangling to a file, so that
we can preserve the original form.

This case is slightly trickier, though, because we can't just call |read|
on the form, since if the the test fails, |*read-suppress*| will be true,
and we won't get anything back. So we use an echo stream to catch the raw
characters that the reader scans, and use that to reconstruct the form.

@l
(defclass read-time-conditional ()
  ((plusp :reader read-time-conditional-plusp :initarg :plusp)
   (test :reader read-time-conditional-test :initarg :test)
   (form :reader read-time-conditional-form :initarg :form)))

(defmethod print-object ((obj read-time-conditional) stream)
  (if *print-marker*
      (format stream "#~:[-~;+~]~S ~A"
              (read-time-conditional-plusp obj)
              (read-time-conditional-test obj)
              (read-time-conditional-form obj))
      (print-unreadable-object (obj stream :type t :identity t))))

(defclass read-time-conditional-marker (read-time-conditional marker) ())

(defmethod marker-boundp ((marker read-time-conditional-marker))
  (if *evaluating*
      (call-next-method)
      t))

(defmethod marker-value ((marker read-time-conditional-marker))
  (if *evaluating*
      (call-next-method)
      (make-instance 'read-time-conditional
                     :plusp (read-time-conditional-plusp marker)
                     :test (read-time-conditional-test marker)
                     :form (read-time-conditional-form marker))))

(defun read-time-conditional-reader (stream sub-char arg)
  (declare (ignore arg))
  (let* ((plusp (ecase sub-char (#\+ t) (#\- nil)))
         (*readtable* (readtable-for-mode nil))
         (test (let ((*package* (find-package "KEYWORD"))
                     (*read-suppress* nil))
                 (read stream t nil t)))
         (*read-suppress* (if plusp (not (featurep test)) (featurep test))))
    (peek-char t stream t nil t)
    (read-with-echo (stream values form)
      (apply #'make-instance 'read-time-conditional-marker
             :plusp plusp :test test :form form
             (and (not *read-suppress*) values (list :value (car values)))))))

(dolist (mode '(:lisp :inner-lisp))
  (set-dispatch-macro-character #\# #\+ #'read-time-conditional-reader @+
                                (readtable-for-mode mode))
  (set-dispatch-macro-character #\# #\- #'read-time-conditional-reader @+
                                (readtable-for-mode mode)))

@t@l
(deftest (read-time-conditional 1)
  (let ((*features* '(:a))
        (*evaluating* nil)
        (*print-marker* t))
    (values (prin1-to-string (marker-value (read-form-from-string "#+a 1")))
            (prin1-to-string (marker-value (read-form-from-string "#-a 1")))))
  "#+:A 1"
  "#-:A 1")

(deftest (read-time-conditional 2)
  (let ((*features* '(:a))
        (*evaluating* t))
    (values (marker-value (read-form-from-string "#+a 1"))
            (marker-value (read-form-from-string "#-b 2"))
            (marker-boundp (read-form-from-string "#-a 1"))
            (marker-boundp (read-form-from-string "#+b 2"))))
  1
  2
  nil
  nil)

@ So much for the standard macro characters. Now we're ready to move
on to \WEB-specific reading. We accumulate \TeX\ mode material such as
commentary, section names, \etc. using the following function, which reads
from |stream| until encountering either \EOF\ or an element of the
|control-chars| argument, which should be a designator for a list of
 characters.

@l
(defun snarf-until-control-char (stream control-chars &aux
                                 (control-chars (if (listp control-chars)
                                                    control-chars
                                                    (list control-chars))))
  (with-output-to-string (string)
    (loop for char = (peek-char nil stream nil *eof* nil)
          until (or (eof-p char) (member char control-chars))
          do (write-char (read-char stream) string))))

@t@l
(deftest snarf-until-control-char
  (with-input-from-string (s "abc*123")
    (values (snarf-until-control-char s #\*)
            (snarf-until-control-char s '(#\a #\3))))
  "abc"
  "*12")

@ In \TeX\ mode (including restricted contexts), we allow embedded Lisp
code to be surrounded by \pb, where it is read in inner-Lisp mode.

@l
(defun read-inner-lisp (stream char)
  (with-mode :inner-lisp
    (read-delimited-list char stream t)))

(dolist (mode '(:TeX :restricted))
  (set-macro-character #\| #'read-inner-lisp nil (readtable-for-mode mode)))

@t@l
(deftest read-inner-lisp
  (with-mode :TeX
    (values (read-from-string "|:foo :bar|")))
  (:foo :bar))

@ The call to |read-delimited-list| in |read-inner-lisp| will only stop at
the closing \v\ if we make it a terminating macro character, overriding its
usual Lisp meaning as an escape character.

@l
(set-macro-character #\| (get-macro-character #\) nil) @+
                     nil (readtable-for-mode :inner-lisp))

@ We make |#\@| a non-terminating dispatching macro character in every
mode, and define some convenience routines for retrieving and setting the
reader macro functions that implement the control codes.

@l
(dolist (mode *modes*)
  ;; The CL standard does not say that calling |make-dispatch-macro-character|
  ;; on a character that's already a dispatching macro character is supposed
  ;; to signal an error, but SBCL does so anyway; hence the |ignore-errors|.
  (ignore-errors
    (make-dispatch-macro-character #\@ t (readtable-for-mode mode))))

(defun get-control-code (sub-char mode)
  (get-dispatch-macro-character #\@ sub-char (readtable-for-mode mode)))

(defun set-control-code (sub-char function &optional (modes *modes*))
  (dolist (mode (if (listp modes) modes (list modes)))
    (set-dispatch-macro-character #\@ sub-char function @+
                                  (readtable-for-mode mode))))

@ The control code \.{@@@@} yields the string \.{"@@"} in all modes, but
it should really only be used in \TeX\ text.

@l
(set-control-code #\@ (lambda (stream sub-char arg)
                        (declare (ignore sub-char stream arg))
                        (string "@")))

@t@l
(deftest literal-@
  (with-mode :TeX
    (values (read-from-string "@@")))
  "@")

@ The control code \.{@@+} prevents an immediately-following newline from
being read, and therefore suppresses the line break that would ordinarily
occur there. It's generally used to give lines of code a bit more room, and
so is only recognized in Lisp mode.

@l
(defun suppress-line-break-reader (stream sub-char arg)
  (declare (ignore sub-char arg))
  (when (eql (peek-char nil stream nil nil t) #\Newline)
    (read-char stream t nil t))
  (values))

(set-control-code #\+ #'suppress-line-break-reader :lisp)

@t@l
(deftest suppress-line-break
  (with-mode :lisp
    (values (read-from-string (format nil "@+~%:foo"))))
  :foo)

@ Non-test sections are introduced by \.{@@\ } or~\.{@@*}, which differ only
in the way they are output during weaving. The reader macro functions that
implement these control codes return an instance of the appropriate section
class.

@l
(defun start-section-reader (stream sub-char arg)
  (declare (ignore stream arg))
  (make-instance (ecase sub-char
                   (#\Space 'section)
                   (#\* 'starred-section))))

(dolist (sub-char '(#\Space #\*))
  (set-control-code sub-char #'start-section-reader '(:limbo :TeX :lisp)))

@ Test sections are handled similarly, but are introduced with \.{@@t}.
Test sections may also be `starred'. Immediately following whitespace
is ignored.

@l
(defun start-test-section-reader (stream sub-char arg)
  (declare (ignore sub-char arg))
  (prog1 (if (and (char= (peek-char t stream t nil t) #\*)
                  (read-char stream t nil t))
             (make-instance 'starred-test-section)
             (make-instance 'test-section))
         (loop until (char/= (peek-char t stream t nil t) #\Newline)
               do (read-char stream t nil t))))

(set-control-code #\t #'start-test-section-reader '(:limbo :TeX :lisp))

@t We bind |*test-sections*| to avoid polluting the global test section
vector.

@l
(deftest start-test-section-reader
  (let ((*test-sections* (make-array 2 :fill-pointer 0)))
    (with-input-from-string (s (format nil "@t~%:foo @t* :bar"))
      (with-mode :lisp
        (values (typep (read s) 'test-section) (read s)
                (typep (read s) 'starred-test-section) (read s)))))
  t :foo
  t :bar)

@ The control codes \.{@@l} and~\.{@@p} (where `l' is for `Lisp' and `p'
is for `program'---both control codes do the same thing) begin the code
part of an unnamed section. They are valid only in \TeX\ mode; every
section must begin with a commentary, even if it is empty. We set the
control codes in Lisp mode only for error detection.

@l
(defclass start-code-marker (marker)
  ((name :reader section-name :initarg :name))
  (:default-initargs :name nil))

(defun start-code-reader (stream sub-char arg)
  (declare (ignore stream sub-char arg))
  (make-instance 'start-code-marker))

(dolist (sub-char '(#\l #\p))
  (set-control-code sub-char #'start-code-reader '(:TeX :lisp)))

@t@l
(deftest start-code-marker
  (with-mode :TeX
    (values-list (mapcar (lambda (marker) (typep marker 'start-code-marker))
                         (list (read-from-string "@l")
                               (read-from-string "@p")))))
  t
  t)

@ The control code \.{@@e} (`e' for `eval') indicates that the following
form should be evaluated by the section reader, {\it in addition to\/}
being tangled into the output file. Evaluated forms should be used only
for establishing state that is needed by the reader: package definitions,
structure definitions that are used with \.{\#S}, \etc.

@l
(defclass evaluated-form-marker (marker) ())

(defun read-evaluated-form (stream sub-char arg)
  (declare (ignore sub-char arg))
  (loop for form = (read stream t nil t)
        until (not (newlinep form)) ; skip over newlines
        finally (return (make-instance 'evaluated-form-marker :value form))))

(set-control-code #\e #'read-evaluated-form :lisp)

@t@l
(deftest (read-evaluated-form 1)
  (let ((marker (read-form-from-string (format nil "@e t"))))
    (and (typep marker 'evaluated-form-marker)
         (marker-value marker)))
  t)

(deftest (read-evaluated-form 2)
  (let ((marker (read-form-from-string (format nil "@e~%t"))))
    (and (typep marker 'evaluated-form-marker)
         (marker-value marker)))
  t)

@ Several control codes, including \.{@@<}, contain `restricted' \TeX\ text,
called {\it control text}, that extends to the next \.{@@>}. When we first
read control text, we ignore inner-Lisp material (that is, Lisp forms
surrounded by \pb). During weaving, we'll re-scan it to pick up such
material.

@l
(defvar *end-control-text* (make-symbol "@>"))
(set-control-code #\> (constantly *end-control-text*) :restricted)

(defun read-control-text (stream &optional
                          (eof-error-p t)
                          (eof-value nil)
                          (recursive-p nil))
  (with-mode :restricted
    (apply #'concatenate 'string
           (loop for text = (snarf-until-control-char stream #\@)
                 as x = (read-preserving-whitespace stream
                                                    eof-error-p eof-value
                                                    recursive-p)
                 collect text
                 if (eq x *end-control-text*) do (loop-finish)
                 else collect x))))

@t@l
(deftest read-control-text
  (with-input-from-string (s "frob |foo|@>")
    (read-control-text s))
  "frob |foo|")

@ The control code \.{@@<} introduces a section name, which extends to the
closing \.{@@>}. Its meaning is context-dependent.

In \TeX\ mode, a name must be followed by \.{=}, which attaches the name to
the current section and begins the code part.

In Lisp and inner-Lisp modes, a name is taken to refer to the section so
named. During tangling, such references in Lisp mode will be replaced with
the code defined for that section. References in inner-Lisp mode are only
citations, and so are not expanded.

@l
(defun make-section-name-reader (definition-allowed-p)
  (lambda (stream sub-char arg)
    (declare (ignore sub-char arg))
    (let* ((name (read-control-text stream t nil t))
           (definitionp (eql (peek-char nil stream nil nil t) #\=)))
      (if definitionp
          (if definition-allowed-p
              (progn
                (read-char stream)
                (make-instance 'start-code-marker :name name))
              @<Signal an error about section definition in Lisp mode@>)
          (if definition-allowed-p
               @<Signal an error about section name use in \TeX\ mode@>
               (let ((named-section (find-section name)))
                 (pushnew *current-section* (used-by named-section))
                 named-section))))))

(set-control-code #\< (make-section-name-reader t) :TeX)
(set-control-code #\< (make-section-name-reader nil) '(:lisp :inner-lisp))

@ @<Condition classes@>=
(define-condition section-name-context-error (error)
  ((name :reader section-name :initarg :name)))

(define-condition section-name-definition-error (section-name-context-error)
  ()
  (:report (lambda (condition stream)
             (format stream "Can't define a named section in Lisp mode: ~A"
                     (section-name condition)))))

(define-condition section-name-use-error (section-name-context-error)
  ()
  (:report (lambda (condition stream)
             (format stream "Can't use a section name in TeX mode: ~A"
                     (section-name condition)))))

@ @<Signal an error about section definition in Lisp mode@>=
(restart-case (error 'section-name-definition-error :name name)
  (use-section ()
    :report "Don't define the section, just use it."
    (find-section name)))

@ @<Signal an error about section name use in \TeX\ mode@>=
(restart-case (error 'section-name-use-error :name name)
  (name-section ()
    :report "Name the current section and start the code part."
    (make-instance 'start-code-marker :name name))
  (cite-section ()
    :report "Assume the section is just being cited."
    (find-section name)))

@t@l
(deftest (read-section-name :TeX)
  (with-mode :TeX
    (section-name (read-from-string "@<foo@>=")))
  "foo")

(deftest (read-section-name :lisp)
  (let ((*named-sections* *sample-named-sections*))
    (with-mode :lisp
      (section-name (read-from-string "@<foo@>"))))
  "foo")

(deftest section-name-definition-error
  (let ((*named-sections* *sample-named-sections*))
    (section-name
     (handler-bind ((section-name-definition-error
                     (lambda (condition)
                       (declare (ignore condition))
                       (invoke-restart 'use-section))))
       (with-mode :lisp
         (read-from-string "@<foo@>=")))))
  "foo")

(deftest section-name-use-error
  (let ((*named-sections* *sample-named-sections*))
    (section-name
     (handler-bind ((section-name-use-error
                     (lambda (condition)
                       (declare (ignore condition))
                       (invoke-restart 'cite-section))))
       (with-mode :TeX
         (read-from-string "@<foo@>")))))
  "foo")

@ When we're accumulating forms from the code part of a section, we'll
interpret two newlines in a row as ending a paragraph, as in \TeX.

@l
(defclass par-marker (newline-marker) ())
(defvar *par* (make-instance 'par-marker))

@ We need one last utility before coming to the main section reader.
When we're accumulating text, we don't want to bother with empty strings.
So we use the following macro, which is like |push|, but does nothing if
the new object is an empty string or |nil|.

@l
(defmacro maybe-push (obj place &aux (g (gensym)))
  `(let ((,g ,obj))
     (when (if (stringp ,g) (plusp (length ,g)) ,g)
       (push ,g ,place))))

@t@l
(deftest maybe-push
  (let ((list '()))
    (maybe-push 'a list)
    (maybe-push nil list)
    (maybe-push "" list)
    (maybe-push 'b list)
    list)
  (b a))

@ We come now to the heart of the \WEB\ parser. This function is a
tiny state machine that models the global syntax of a \WEB\ file.
(We can't just use reader macros since sections and their parts lack
explicit closing delimiters.) It returns a list of |section| objects.

@l
(defun read-sections (input-stream &key (appendp t))
  (with-charpos-input-stream (stream input-stream)
    (flet ((finish-section (section commentary code)
             @<Trim whitespace and reverse...@>
             (setf (section-commentary section) commentary)
             (setf (section-code section) code)
             (when (section-name section)
               (let ((named-section (find-section (section-name section))))
                 (if appendp
                     (push section (named-section-sections named-section))
                     (setf (named-section-sections named-section) @+
                           (list section)))))
             section))
      (prog (form commentary code section sections)
         (setq section (make-instance 'limbo-section))
         @<Accumulate limbo text in |commentary|@>
       commentary
         @<Finish the last section...@>
         @<Accumulate \TeX-mode material in |commentary|@>
       lisp
         @<Accumulate Lisp-mode material in |code|@>
       eof
         (push (finish-section section commentary code) sections)
         (return (nreverse sections))))))

@ Limbo text is \TeX\ text that proceeds the first section marker, and we
treat it as commentary for a special section with no code. Note that
inner-Lisp material is not recognized in limbo text.

@<Accumulate limbo text in |commentary|@>=
(with-mode :limbo
  (loop
    (maybe-push (snarf-until-control-char stream #\@) commentary)
    (setq form (read-preserving-whitespace stream nil *eof* nil))
    (typecase form
      (eof (go eof))
      (section (go commentary))
      (t (push form commentary)))))

@ @<Finish the last section and initialize section variables@>=
(push (finish-section section commentary code) sections)
(check-type form section)
(setq section form
      commentary '()
      code '())

@ The commentary part that begins a section consists of \TeX\ text and
inner-Lisp material surrounded by \pb. It is terminated by either the start
of a new section, the beginning of the code part, or \EOF. If a code part
is detected, we also set the name of the current section, which may be |nil|.

@<Accumulate \TeX-mode material in |commentary|@>=
(with-mode :TeX
  (loop
    (maybe-push (snarf-until-control-char stream '(#\@ #\|)) commentary)
    (setq form (read-preserving-whitespace stream nil *eof* nil))
    (typecase form
      (eof (go eof))
      (section (go commentary))
      (start-code-marker (setf (section-name section) (section-name form))
                         (go lisp))
      (t (push form commentary)))))

@ The code part of a section consists of zero or more Lisp forms and is
terminated by either \EOF\ or the start of a new section. This is also
where we evaluate \.{@@e} forms.

@<Accumulate Lisp-mode material in |code|@>=
(check-type form start-code-marker)
(with-mode :lisp
  (loop
    (setq form (read-preserving-whitespace stream nil *eof* nil))
    (typecase form
      (eof (go eof))
      (section (go commentary))
      (start-code-marker @+
       @<Complain about starting a section without a commentary part@>)
      (newline-marker @<Maybe push the newline marker@>)
      (evaluated-form-marker (let ((form (marker-value form)))
                               (let ((*evaluating* t)
                                     (*readtable* (readtable-for-mode nil)))
                                 (eval (tangle form)))
                               (push form code)))
      (t (push form code)))))

@ @<Complain about starting a section without a commentary part@>=
(cerror "Start a new unnamed section with no commentary."
        'section-lacks-commentary :stream stream)
(setq form (make-instance 'section))
@<Finish the last section...@>

@ @<Condition classes@>=
(define-condition section-lacks-commentary (parse-error)
  ((stream :initarg :stream :reader section-lacks-commentary-stream))
  (:report (lambda (error stream)
             (let* ((input-stream
                     (do ((stream (section-lacks-commentary-stream error)))
                         (())
                       (typecase stream
                         (echo-stream
                          (setq stream (echo-stream-input-stream stream)))
                         (t (return stream)))))
                    (position (file-position input-stream))
                    (pathname (when (typep input-stream 'file-stream)
                                (pathname input-stream))))
               (format stream
                       "~@<Can't start a section with a code part ~
~:[~;~:*at position ~D in file ~A.~]~:@>"
                       position (or pathname input-stream))))))

@ We won't push a newline marker if no code has been accumulated yet, and
we'll push a paragraph marker instead if there are two newlines in a row.

@<Maybe push...@>=
(unless (null code)
  (cond ((newlinep (car code))
         (pop code)
         (push *par* code))
        (t (push form code))))

@ We trim trailing whitespace from the last string in |commentary|, leading
whitespace from the first, and any trailing newline marker from |code|.
(Leading newlines are handled in |@<Accumulate Lisp-mode...@>|.)

@<Trim whitespace and reverse |commentary| and |code|@>=
(when (stringp (car commentary))
  (rplaca commentary (string-right-trim *whitespace* (car commentary))))
(setq commentary (nreverse commentary))
(when (stringp (car commentary))
  (rplaca commentary (string-left-trim *whitespace* (car commentary))))
(setq code (nreverse (member-if-not #'newlinep code)))

@*The tangler. Tangling involves recursively replacing each reference to a
named section with the code accumulated for that section. The function
|tangle-1| expands one level of such references, returning the
possibly-expanded form and a boolean representing whether or not any
expansions were actually performed.

Note that this is a splicing operation, like `\.{,@@}', not a simple
substitution, like normal Lisp macro expansion:
if \X$n$:foo\X$\mathrel\E$|(x y)|, then
\((tangle-1 \'(a \X$n$:foo\X\ b))\)$\;\to\;$|(a x y b)|,~|t|.

Tangling also replaces bound markers with their associated values, and
removes unbound markers.

@l
(defun tangle-1 (form &key (expand-named-sections-p t))
  (flet ((tangle-1 (form)
           (tangle-1 form :expand-named-sections-p expand-named-sections-p)))
    (typecase form
      (marker (values (marker-value form) t))
      (atom (values form nil))
      ((cons named-section *)
       (multiple-value-bind (d cdr-expanded-p) (tangle-1 (cdr form))
         (if expand-named-sections-p
            (values (append (section-code (car form)) d) t)
            (values (cons (car form) d) cdr-expanded-p))))
      ((cons marker *)
       (values (if (marker-boundp (car form))
                   (cons (marker-value (car form)) (tangle-1 (cdr form)))
                   (tangle-1 (cdr form)))
               t))
      (t (multiple-value-bind (a car-expanded-p) (tangle-1 (car form))
           (multiple-value-bind (d cdr-expanded-p) (tangle-1 (cdr form))
             (values (if (and (eql a (car form))
                              (eql d (cdr form)))
                         form
                         (cons a d))
                     (or car-expanded-p cdr-expanded-p))))))))

@t@l
(deftest (tangle-1 1)
  (tangle-1 (read-form-from-string ":a"))
  :a
  nil)

(deftest (tangle-1 2)
  (tangle-1 (read-form-from-string "(:a :b :c)"))
  (:a :b :c)
  t)

(deftest (tangle-1 3)
  (let ((*named-sections* *sample-named-sections*))
    (eql (tangle-1 (read-form-from-string "@<foo@>"))
         (find-sample-section "foo")))
  t)

@ |tangle| repeatedly calls |tangle-1| on |form| until it can no longer be
expanded. Like |tangle-1|, it returns the possibly-expanded form and an
`expanded' flag. This code is adapted from SBCL's |macroexpand|.

@l
(defun tangle (form &key (expand-named-sections-p t))
  (labels ((expand (form expanded)
             (multiple-value-bind (new-form newly-expanded-p)
                 (tangle-1 form
                           :expand-named-sections-p expand-named-sections-p)
               (if newly-expanded-p
                   (expand new-form t)
                   (values new-form expanded)))))
    (expand form nil)))

@t@l
(deftest tangle
  (let ((*named-sections* *sample-named-sections*))
    (tangle (read-form-from-string (format nil "(:a @<foo@>~% :b)"))))
  (:a :foo :b)
  t)

@ This little utility function returns a list of all of the forms in all
of the unnamed sections' code parts. This is our first-order approximation
of the complete program; if you tangle it, you get the whole thing.

@l
(defun unnamed-section-code-parts (sections)
  (mapappend #'section-code (coerce (remove-if #'section-name sections) 'list)))

@ We're now ready for the high-level tangler interface. We begin with
|load-web|, which uses a helper function, |load-web-from-stream|, so that
it can handle input from an arbitrary stream. The logic is straightforward:
we loop over the tangled forms read from the stream, evaluating each one in
turn.

Note that like |load|, we bind |*readtable*| and |*package*| to their
current values, so that assignments to those variables in the \WEB\ code
will not affect the calling environment.

@l
(defun load-web-from-stream (stream print &key (appendp t) &aux
                             (*readtable* *readtable*)
                             (*package* *package*)
                             (*evaluating* t))
  (dolist (form (tangle (unnamed-section-code-parts
                         (read-sections stream :appendp appendp))) t)
    (if print
        (let ((results (multiple-value-list (eval form))))
          (format t "~&; ~{~S~^, ~}~%" results))
        (eval form))))

(defun load-web (filespec &key
                 (verbose *load-verbose*)
                 (print *load-print*)
                 (if-does-not-exist t)
                 (external-format :default))
  "Load the web given by FILESPEC into the Lisp environment."
  @<Initialize global variables@>
  (when verbose (format t "~&; loading WEB from ~S~%" filespec))
  (if (streamp filespec)
      (load-web-from-stream filespec print)
      (with-open-file (stream (merge-pathnames filespec @+
                                               (make-pathname :type "CLW" @+
                                                              :case :common))
                       :direction :input
                       :external-format external-format
                       :if-does-not-exist (if if-does-not-exist :error nil))
        (load-web-from-stream stream print))))

@ This next function exists solely for the sake of front-ends that wish to
load a piece of a \WEB, such as the author's `\.{clweb.el}'. Note that it
does {\it not\/} initialize the global variables like |*named-sections*|;
this allows for incremental redefinition.

@l
(defun load-sections-from-temp-file (file appendp &aux
                                     (truename (probe-file file)))
  "Load web sections from FILE, then delete it."
  (when truename
    (unwind-protect
         (with-open-file (stream truename :direction :input)
           (load-web-from-stream stream t :appendp appendp))
      (delete-file truename))))


@ Both |tangle-file| and |weave|, below, take a |tests-file| argument that
has slightly hairy defaulting behavior. If it's supplied and is non-|nil|,
then we use a pathname derived from the one given by merging in a default
type (\.{"lisp"} in the case of tangling, \.{"tex"} for weaving). If it's
not supplied, then we construct a pathname from the output file by
appending the string \.{"-tests"} to its name component. Finally, if the
argument is supplied and is |nil|, then no tests file will be written at
all.

@l
(defun tests-file-pathname (output-file type &key
                            (tests-file nil tests-file-supplied-p)
                            &allow-other-keys)
  (if tests-file
      (merge-pathnames tests-file (make-pathname :type type :case :common))
      (unless tests-file-supplied-p
        (make-pathname :name (concatenate 'string
                                          (pathname-name output-file @+
                                                         :case :common)
                                          "-TESTS")
                       :type type
                       :defaults output-file
                       :case :common))))

@t@l
(deftest (tests-file-pathname 1)
  (equal (tests-file-pathname (make-pathname :name "FOO" :case :common) "LISP"
                              :tests-file (make-pathname :name "BAR" @+
                                                         :case :common))
         (make-pathname :name "BAR" :type "LISP" :case :common))
  t)

(deftest (tests-file-pathname 2)
  (equal (tests-file-pathname (make-pathname :name "FOO" :case :common) "TEX")
         (make-pathname :name "FOO-TESTS" :type "TEX" :case :common))
  t)

(deftest (tests-file-pathname 3)
  (tests-file-pathname (make-pathname :name "FOO" :case :common) "LISP"
                       :tests-file nil)
  nil)

@ The file tangler operates by writing out the tangled code to a Lisp source
file and then invoking the file compiler on that file. The arguments are
essentially the same as those to |cl:compile-file|, except for the
|tests-file| keyword argument, which specifies the file to which the test
sections' code should be written.

@l
(defun tangle-file (input-file &rest args &key
                    output-file
                    tests-file
                    (verbose *compile-verbose*)
                    (print *compile-print*)
                    (external-format :default) &allow-other-keys &aux
                    (input-file (merge-pathnames @+
                                 input-file @+
                                 (make-pathname :type "CLW" :case :common)))
                    (output-file (apply #'compile-file-pathname @+
                                        input-file :allow-other-keys t args))
                    (lisp-file (merge-pathnames @+
                                (make-pathname :type "LISP" :case :common) @+
                                output-file))
                    (tests-file (apply #'tests-file-pathname @+
                                       output-file "LISP" args))
                    (*readtable* *readtable*)
                    (*package* *package*))
  "Tangle and compile the web in INPUT-FILE, producing OUTPUT-FILE."
  (declare (ignore output-file tests-file))
  (when verbose (format t "~&; tangling web from ~A:~%" input-file))
  @<Initialize global variables@>
  (with-open-file (input input-file
                   :direction :input
                   :external-format external-format)
    (read-sections input))
  @<Complain about any unused named sections@>
  (flet ((write-forms (sections output-file)
           (with-open-file (output output-file
                            :direction :output
                            :if-exists :supersede
                            :external-format external-format)
             (format output ";;;; TANGLED WEB FROM \"~A\". DO NOT EDIT." @+
                     input-file)
             (let ((*evaluating* nil)
                   (*print-marker* t))
               (dolist (form (tangle (unnamed-section-code-parts sections)))
                 (pprint form output))))))
    (when (and tests-file
               (> (length *test-sections*) 1)) ; there's always a limbo section
      (when verbose (format t "~&; writing tests to ~A~%" tests-file))
      (write-forms *test-sections* tests-file)
      (compile-file tests-file ; use default output file
                    :verbose verbose
                    :print print
                    :external-format external-format))
    (when verbose (format t "~&; writing tangled code to ~A~%" lisp-file))
    (write-forms *sections* lisp-file)
    (apply #'compile-file lisp-file :allow-other-keys t args)))

@ A named section doesn't do any good if it's never referenced, so we issue
warnings about unused named sections.

@<Condition classes@>=
(define-condition unused-named-section-warning (simple-warning) ())

@ @<Complain about any unused...@>=
(let ((unused-sections '()))
  (labels ((collect-unused-sections (section)
             (when section
               (collect-unused-sections (left-child section))
               (collect-unused-sections (right-child section))
               (when (null (used-by section))
                 (push section unused-sections)))))
    (collect-unused-sections *named-sections*)
    (map nil
         (lambda (section)
           (warn 'unused-named-section-warning
                 :format-control "Unused named section <~A>."
                 :format-arguments (list (section-name section))))
         (sort unused-sections #'< :key #'section-number))))

@*The weaver. The top-level weaver interface is modeled after
|cl:compile-file|. The function |weave| reads the \WEB\ |input-file| and
produces an output \TeX\ file named by |output-file|. If |output-file| is
not supplied or is |nil|, a pathname will be generated from |input-file| by
replacing its |type| component with \.{"tex"}.

If |verbose| is true, |weave| prints a message in the form of a comment to
standard output indicating what file is being woven. If |verbose| is not
supplied, the value of |*weave-verbose*| is used.

If |print| is true, the section number of each section encountered is printed
to standard output, with starred sections prefixed with \.{*}. If |print|
is not supplied, the value of |*weave-print*| is used.

Finally, the |external-format| argument specifies the external file format
to be used when opening both the input file and the output file.
{\it N.B.:} standard \TeX\ only handles 8-bit characters, and the encodings
for non-printable-\csc{ascii} characters vary widely.

If successful, |weave| returns the truename of the output file. 

@l
(defun weave (input-file &rest args &key
              output-file tests-file
              (verbose *weave-verbose*)
              (print *weave-print*)
              (if-does-not-exist t)
              (external-format :default) &aux
              (input-file (merge-pathnames input-file
                                           (make-pathname :type "CLW" @+
                                                          :case :common)))
              (output-file (if output-file
                               (merge-pathnames output-file
                                                (make-pathname :type "TEX" @+
                                                               :case :common))
                               (merge-pathnames (make-pathname :type "TEX" @+
                                                               :case :common)
                                                input-file)))
              (tests-file (apply #'tests-file-pathname @+
                                 output-file "TEX" args))
              (*readtable* *readtable*)
              (*package* *package*))
  "Weave the web contained in INPUT-FILE, producing the TeX file OUTPUT-FILE."
  (declare (ignore tests-file))
  (when verbose (format t "~&; weaving web from ~A:~%" input-file))
  @<Initialize global variables@>
  (with-open-file (input input-file
                   :direction :input
                   :external-format external-format
                   :if-does-not-exist (if if-does-not-exist :error nil))
    (read-sections input))
  (when (and tests-file
             (> (length *test-sections*) 1)) ; there's always a limbo section
    (when verbose (format t "~&; weaving tests to ~A~%" tests-file))
    (weave-sections *test-sections* tests-file
                    :print print
                    :external-format external-format))
    (when verbose (format t "~&; weaving sections to ~A~%" output-file))
    (weave-sections *sections* output-file
                    :print print
                    :external-format external-format))

@ @<Global variables@>=
(defvar *weave-verbose* t)
(defvar *weave-print* t)

@ The individual sections and their contents are printed using the pretty
printer with a customized dispatch table.

@<Global variables@>=
(defparameter *weave-pprint-dispatch* (copy-pprint-dispatch nil))

@ The following routine does the actual writing of the sections to the output
file.

@l
(defun weave-sections (sections output-file &key
                       (print *weave-print*)
                       (external-format :default))
  (with-open-file (output output-file
                   :direction :output
                   :external-format external-format
                   :if-exists :supersede)
    (format output "\\input clwebmac~%")
    (flet ((write-section (section)
             (write section
                    :stream output
                    :case :downcase
                    :escape nil
                    :pretty t
                    :pprint-dispatch *weave-pprint-dispatch*
                    :right-margin 1000)))
      (if print
          (pprint-logical-block (nil nil :per-line-prefix "; ")
            (map nil
                 (lambda (section)
                   (format t "~:[~;~:@_*~]~D~:_ "
                           (typep section 'starred-section)
                           (section-number section))
                   (write-section section))
                 sections))
          (map nil #'write-section sections)))
    (format output "~&\\bye~%")
    (truename output)))

@ The rest of the weaver consists entirely of pretty-printing routines that
are installed in |*weave-pprint-dispatch*|.

@l
(defun set-weave-dispatch (type-specifier function &optional (priority 0))
  (set-pprint-dispatch type-specifier function priority @+
                       *weave-pprint-dispatch*))

@ \TeX-mode material is represented as a list of strings containing pure
\TeX\ text and lists of (inner-)Lisp forms. We bind |*inner-lisp*| to true
when we're printing inner-Lisp-mode material so that we can adjust our
pretty-printing.

@<Global variables@>=
(defvar *inner-lisp* nil)

@ @l
(defun print-TeX (stream tex-mode-material)
  (dolist (x tex-mode-material)
    (etypecase x
      (string (write-string x stream))
      (list (let ((*inner-lisp* t))
              (dolist (form x)
                (format stream "\\(~W\\)" form)))))))

@ Control text (like section names) and comments are initially read as
strings containing pure \TeX\ text, but they actually contain restricted
\TeX-mode material, which may include inner-Lisp material. This routine
re-reads such strings and picks up any inner-Lisp material.

@l
(defun read-TeX-from-string (input-string)
  (with-mode :restricted
    (with-input-from-string (stream input-string)
      (loop for text = (snarf-until-control-char stream #\|)
            for forms = (read-preserving-whitespace stream nil *eof* nil)
            if (plusp (length text)) collect text
            if (eof-p forms) do (loop-finish) else collect forms))))

@ @l
(defun print-limbo (stream section)
  (let ((commentary (section-commentary section)))
    (when commentary
      (print-TeX stream commentary)
      (terpri stream))))

(set-weave-dispatch 'limbo-section #'print-limbo 1)

@ % FIXME: This needs to be broken up and documented.
@l
(defun print-section (stream section)
  (format stream "~&\\~:[M~;N{1}~]{~:[~;T~]~D}" ; \.{\{1\}} should be depth
          (typep section 'starred-section)
          (typep section 'test-section)
          (section-number section))
  (let* ((commentary (section-commentary section))
         (name (section-name section))
         (named-section (and name (find-section name)))
         (code (section-code section)))
    (print-TeX stream commentary)
    (fresh-line stream)
    (cond ((and commentary code) (format stream "\\Y\\B~%"))
          (code (format stream "\\B~%")))
    (when named-section
      (print-section-name stream named-section)
      (format stream "${}~:[\\mathrel+~;~]\\E{}$~%"
              (= (section-number section) (section-number named-section))))
    (when code
      (dolist (form code)
        (if (list-marker-p form)
            (format stream "~@<\\+~@;~W~;\\cr~:>" form)
            (format stream "~W~:[\\par~;~]" form (newlinep form))))
      (format stream "~&\\egroup~%")) ; matches \.{\\bgroup} in \.{\\B}
    (when (and (typep section 'test-section) (section-code section))
      (format stream "\\T~P~D.~%"
              (length (section-code section))
              (section-number (test-for-section section))))
    (when named-section
      (print-xrefs stream #\A
                   (remove section (named-section-sections named-section)))
      (print-xrefs stream #\U
                   (remove section (used-by named-section)))))
  (format stream "\\fi~%"))

(set-weave-dispatch 'section #'print-section)

@ The cross-references lists use the macros \.{\\A} (for `also'),
\.{\\U} (for `use'), \.{\\Q} (for `quote'), and their pluralized variants,
along with the conjunction macros \.{\\ET} (for two section numbers)
and~\.{\\ETs} (for between the last of three or more).

@l
(defun print-xrefs (stream kind xrefs)
  (when xrefs
    ;; This was 16 lines of code over two sections in \CWEB. I love |format|.
    (format stream "\\~C~{~#[~;~D~;s ~D\\ET~D~:;s~@{~#[~;\\ETs~D~;~D~:;~D, ~]~}~]~}.~%"
            kind (sort (mapcar #'section-number xrefs) #'<))))

@ @l
(defun print-section-name (stream named-section)
  (format stream "\\X~D:" (section-number named-section))
  (print-TeX stream (read-TeX-from-string (section-name named-section)))
  (write-string "\\X" stream))

(set-weave-dispatch 'named-section #'print-section-name)

@ Because we're outputting \TeX, we need to carefully escape characters
that \TeX\ treats as special. Unfortunately, because \TeX's syntax is so
malleable (not unlike Lisp's), it's nontrivial to decide what to escape,
how, and when.

The following routine is the basis for most of the escaping. It writes
|string| to the output stream designated by |stream|, escaping the
characters given in the a-list |escape-chars|. The entries in this a-list
should be of the form `(\metasyn{characters}~.~\metasyn{replacement})',
where \metasyn{replacement} describes how to escape each of the characters
in \metasyn{characters}. Suppose $c$ is a character in |string| that
appears in one of the \metasyn{characters} strings. If the corresponding
\metasyn{replacement} is a single character, then |write-string-escaped|
will output it prior to every occurrence of $c$. If \metasyn{replacement}
is a string, it will be output {\it instead of\/} every occurrence of $c$
in the input. Otherwise, $c$ will be output without escaping.

@l
(defparameter *tex-escape-alist*
  '((" \\%&#$^_~<>" . #\\) ("{" . "$\\{$") ("}" . "$\\}$")))

(defun write-string-escaped (string &optional stream @+
                             (escape-chars *tex-escape-alist*) &aux
                             (stream (case stream
                                       ((t) *terminal-io*)
                                       ((nil) *standard-output*)
                                       (otherwise stream))))
  (loop for char across string
        as escape = (cdr (assoc char escape-chars :test #'find))
        if escape
          do (etypecase escape
               (character (write-char escape stream)
                          (write-char char stream))
               (string (write-string escape stream)))
        else
          do (write-char char stream)))

@t@l
(deftest write-string-escaped
  (with-output-to-string (s)
    (write-string-escaped "foo#{bar}*baz" s))
  "foo\\#$\\{$bar$\\}$*baz")

@ We need to be careful about embedded newlines in string literals.

@l
(defun print-string (stream string)
  (loop for last = 0 then (1+ newline)
        for newline = (position #\Newline string :start last)
        as line = (subseq string last newline)
        do (format stream "\\.{~:[~;\"~]" (zerop last))
           (write-string-escaped line stream
                                 (list* '("{*}" . #\\)
                                        '("\\" . "\\\\\\\\")
                                        '("\"" . "\\\\\"")
                                        *tex-escape-alist*))
           (format stream "~:[~;\"~]}" (null newline))
        when newline do (format stream "\\cr~:@_") else do (loop-finish)))

(set-weave-dispatch 'string #'print-string)

@ @l
(defun print-char (stream char)
  (let ((graphicp (and (graphic-char-p char)
                       (standard-char-p char)))
        (name (char-name char)))
    (write-string "\\#\\CH{" stream)
    (write-string-escaped (if (and name (not graphicp))
                              name
                              (make-string 1 :initial-element char))
                          stream
                          (list* '("{}" . #\\) *tex-escape-alist*))
    (write-string "}" stream)
    char))

(set-weave-dispatch 'character #'print-char)

@ Symbols are printed by first writing them out to a string, then printing
that string. This relieves us of the burden of worrying about case conversion,
package prefixes, and the like---we just let the Lisp printer handle it.

Lambda-list keywords and symbols in the `keyword' package have specialized
\TeX\ macros that add a bit of emphasis.

@l
(defun print-symbol (stream symbol)
  (let ((group-p (cond ((member symbol lambda-list-keywords)
                        (write-string "\\K{" stream))
                       ((keywordp symbol)
                        (write-string "\\:{" stream)))))
    (write-string-escaped (write-to-string symbol :escape nil :pretty nil) @+
                          stream)
    (when group-p (write-string "}" stream))))

(set-weave-dispatch 'symbol #'print-symbol)

@ Lambda gets special treatment.

@l
(set-weave-dispatch '(eql lambda)
  (lambda (stream obj)
    (declare (ignore obj))
    (write-string "\\L" stream))
  1)

@ Next, we turn to list printing, and the tricky topic of indentation. On
the assumption that the human writing the code in a \WEB\ is smarter than
any sort of automatic indentation that we might be able to do, we attempt
to approximate (but {\it not\/} duplicate) on output the indentation given
in the input by utilizing the character position values that the list
reader stores in the list markers.

We do this by breaking up lists into {\it logical blocks\/}---the same sort
of (abstract) entities that the pretty printer uses, but made concrete
here. A logical block defines a left edge for a list of forms, some of
which may be nested logical blocks.

@l
(defstruct (logical-block (:constructor make-logical-block (list)))
  list)

@ The analysis of the indentation is performed by a recursive |labels|
routine, to which we will come in a moment. That routine operates on an
list of |(form . charpos)| conses, taken from a list marker. Building this
list does cost us some consing, but vastly simplifies the logic, since we
don't have to worry about keeping multiple indices synchronized.

@l
(defun analyze-indentation (list-marker)
  (declare (type list-marker list-marker))
  (labels ((find-next-newline (list) (member-if #'newlinep list :key #'car))
           (next-logical-block (list) @<Build a logical block from |list|@>))
    ;; Sanity check.
    (assert (= (length (list-marker-list list-marker))
               (length (list-marker-charpos list-marker)))
            ((list-marker-list list-marker) (list-marker-charpos list-marker))
            "List marker's list and charpos-list aren't the same length.")
    (next-logical-block (mapcar #'cons
                                (list-marker-list list-marker)
                                (list-marker-charpos list-marker)))))

@ To build a logical block, we identify groups of sub-forms that share a
common left margin, which we'll call the {\it block indentation}. If that
left margin is to the right of that of the current block, we recursively
build a new subordinate logical block. The block ends when the first form
on the next line falls to the left of the current block, or we run out of
forms.

For example, consider the following simple form:
\smallskip\hskip2\parindent
\vbox{\B\+(first \!&second\cr\+&third)\cr\egroup}
\smallskip\noindent We start off with an initial logical block whose
indentation is the character position of |first|: this is the {\it block
indentation}. Then we look at |second|, and see that the first form on the
following line, |third|, has the same position, and that it exceeds the
current indentation level. And so we recurse, appending to the new logical
block until we encounter a form whose indentation is less than the new
block indentation, or, as in this trivial example, the end of the list.

More concretely, |next-logical-block| returns two values: the logical block
constructed, and the unused portion of the list, which will always either
be |nil| (we consumed the rest of the forms), or begin with a newline.

We keep a pointer to the next newline in |newline|, and |next-indent| is
the indentation of the immediately following form, which will become the
current indentation when we pass |newline|. As we do so, we store the
difference between the current indentation and the block indentation in
the newline marker, so that the printing routine, below, doesn't have to
worry about character positions at all: it can just look at the newline
markers and the logical block structure.

As an optimization, if we build a block that doesn't directly contain any
newlines---a trivial logical block---we simply return a list of sub-forms
instead of a logical block structure. This allows the printer to elide the
alignment tabs, and makes the resulting \TeX\ much simpler.

@<Build a logical block...@>=
(do* ((block '())
      (block-indent (cdar list))
      (indent block-indent)
      (newline (find-next-newline list))
      (next-indent (cdadr newline)))
     ((or (endp list)
          (and (eq list newline) next-indent (< next-indent block-indent)))
      (values (if (notany #'newlinep block)
                  (nreverse block)
                  (make-logical-block (nreverse block)))
              list))
  (if (and indent next-indent
           (> next-indent indent)
           (= next-indent (cdar list)))
      (multiple-value-bind (sub-block tail) (next-logical-block list)
        (check-type (caar tail) (or newline-marker null))
        (push sub-block block)
        (setq list tail))
      (let ((next (car (pop list))))
        (push next block)
        (when (and list (newlinep next))
          (setf indent (cdar list)
                (indentation next) (- indent block-indent)
                newline (find-next-newline list)
                next-indent (cdadr newline))))))

@ Printing list markers is now simple, since the complexity is all in the
logical blocks$\ldots$

@l
(defun print-list (stream list-marker)
  (let ((block (analyze-indentation list-marker)))
    (etypecase block
      (list (format stream "~<(~;~@{~W~^ ~}~;)~:>" block))
      (logical-block (format stream "(~W)" block)))))

(set-weave-dispatch 'list-marker #'print-list)

@ $\ldots$but even here, it's not that bad. We start with a \.{\\!}, which
is just an alias for \.{\\cleartabs}. Then we call (unsurprisingly)
|pprint-logical-block|, using a per-line-prefix for our alignment tabs.

In the loop, we keep a one-token look-ahead to check for newlines, so that
we can output separating spaces when and only when there isn't a newline
coming up.

The logical-block building machinery above set the indentation on newlines
to the difference in character positions of the first form following
the newline and the block indentation. For differences of 1 or~2 columns,
we use a single quad (\.{\\1}); for any more, we use two (\.{\\2}).

@l
(defun print-logical-block (stream block)
  (write-string "\\!" stream)
  (pprint-logical-block (stream (logical-block-list block) :per-line-prefix "&")
    (do (indent
         next
         (obj (pprint-pop) next))
        (nil)
      (cond ((newlinep obj)
             (format stream "\\cr~:@_")
             (setq indent (indentation obj))
             (pprint-exit-if-list-exhausted)
             (setq next (pprint-pop)))
            (t (format stream "~@[~[~;\\1~;\\1~:;\\2~]~]~W" indent obj)
               (setq indent nil)
               (pprint-exit-if-list-exhausted)
               (setq next (pprint-pop))
               (unless (newlinep next)
                 (write-char #\Space stream)))))))

(set-weave-dispatch 'logical-block #'print-logical-block)

@ Finally, we come to the printing of markers. These are all quite
straightforward; the only thing to watch out for is the priorities.
Because |pprint-dispatch| doesn't respect sub-type relationships,
we need to set a higher priority for a sub-class than for its parent
if we want a specialized pretty-printing routine.

Many of these routines output \TeX\ macros defined in \.{clwebmac.tex},
which see.

@ @l
(set-weave-dispatch 'newline-marker
  (lambda (stream obj)
    (declare (ignore obj))
    (terpri stream)))

(set-weave-dispatch 'par-marker
  (lambda (stream obj)
    (declare (ignore obj))
    (format stream "~&\\Y~%"))
  1)

@ @l
(set-weave-dispatch 'empty-list-marker
  (lambda (stream obj)
    (declare (ignore obj))
    (write-string "()" stream)))

(set-weave-dispatch 'consing-dot-marker
  (lambda (stream obj)
    (declare (ignore obj))
    (write-char #\. stream)))

@ @l
(set-weave-dispatch 'quote-marker
  (lambda (stream obj)
    (format stream "\\'~W" (quoted-form obj))))

@ @l
(set-weave-dispatch 'comment-marker
  (lambda (stream obj)
    (write-string "\\C{" stream)
    (print-TeX stream (read-TeX-from-string (comment-text obj)))
    (write-string "}" stream)))

@ @l
(set-weave-dispatch 'backquote-marker
  (lambda (stream obj)
    (format stream "\\`~W" (backq-form obj))))

(set-weave-dispatch 'comma-marker
  (lambda (stream obj)
    (format stream "\\CO{~@[~C~]}~W"
            (comma-modifier obj)
            (comma-form obj))))

@ @l
(set-weave-dispatch 'function-marker
  (lambda (stream obj)
    (format stream "\\#\\'~S" (quoted-form obj)))
  1)

@ @l
(set-weave-dispatch 'simple-vector-marker
  (lambda (stream obj)
    (format stream "\\#~@[~D~]~S"
            (and (slot-boundp obj 'length)
                 (slot-value obj 'length))
            (slot-value obj 'elements))))

(set-weave-dispatch 'bit-vector-marker
  (lambda (stream obj)
    (format stream "\\#~@[~D~]*~{~[0~;1~]~}"
            (and (slot-boundp obj 'length)
                 (slot-value obj 'length))
            (map 'list #'identity
                 (slot-value obj 'elements))))
  1)

@ @l
(set-weave-dispatch 'read-time-eval-marker
  (lambda (stream obj)
    (format stream "\\#.~W" (read-time-eval-form obj))))

@ @l
(set-weave-dispatch 'radix-marker
  (lambda (stream obj)
    (format stream "$~VR_{~2:*~D}$"
            (radix-marker-base obj) (marker-value obj))))

@ @l
(set-weave-dispatch 'structure-marker
  (lambda (stream obj)
    (format stream "\\#S~W" (structure-marker-form obj))))

@ @l
(set-weave-dispatch 'read-time-conditional-marker
  (lambda (stream obj)
    (format stream "\\#~:[--~;+~]\\RC{~S"
            (read-time-conditional-plusp obj)
            (read-time-conditional-test obj))
    (write-char #\Space stream)
    (write-string-escaped (read-time-conditional-form obj) stream)
    (write-char #\} stream)))

@*The walker. Our last major task is to produce an index of every
interesting symbol that occurs in a web (we'll define what makes a
symbol `interesting' later). We would like separate entries for each
kind of object that a given symbol names: e.g., local or global function,
lexical or special variable, \etc. And finally, we should note whether
a given occurrence of a symbol is a definition/binding or just a use.

In order to accomplish this, we need to walk the tangled code of the
entire program, since the meaning of a symbol in Common Lisp depends,
in general, on its lexical environment, which can only be determined
by code walking. For reasons that will be explained later, we'll
actually be walking a special sort of munged code that isn't exactly
Common Lisp. And because of this, none of the available code walkers
will quite do what we want. So we'll roll our own.

@ We'll pass around instances of a |walker| class during our code walk
to provide a hook (via subclassing) for overriding walker methods.

@l
(defclass walker () ())

@ The walker protocol consists of a handful of generic functions, which
we'll describe as we come to them.

@l
@<Walker generic functions@>

@ We'll use the environments \csc{api} defined in \cltl, since even
though it's not part of the Common Lisp standard, it's widely supported,
and does everything we need it to do.

Allegro Common Lisp has an additional function,
|ensure-portable-walking-environment|, that needs to be called on
any environment object that a portable walker uses; we'll provide
a trivial definition for other Lisps.

@l
(unless (fboundp 'ensure-portable-walking-environment)
  (defun ensure-portable-walking-environment (env) env))

@ Allegro doesn't define |parse-macro| or |enclose|, so we'll need
to provide our own definitions. In fact, we'll use our own version
of |enclose| on all implementations (note that it's shadowed in
the package definition at the beginning of the program). Thanks
to Duane Rettig of Franz,~Inc.\ for the idea behind this trivial
implementation (post to comp.lang.lisp of 18~Oct, 2004, message-id
\metasyn{4is97u4vv.fsf@@franz.com}).

@l
(defun enclose (lambda-expression &optional env
                (walker (make-instance 'walker)))
  (coerce (walk-form walker lambda-expression env)
          'function))

@ The following code for |parse-macro| is obviously extremely
implementation-specific; a portable version would be much more complex.

@l
(unless (fboundp 'parse-macro)
  (defun parse-macro (name lambda-list body &optional env)
    (declare (ignorable name lambda-list body env))
    #+allegro (excl::defmacro-expander `(,name ,lambda-list ,@body) env)
    #-allegro (error "PARSE-MACRO not implemented")))

@ The good people at Franz also decided that they needed an extra value
returned from both |variable-information| and |function-information|.
But instead of doing the sensible thing and adding that extra value at
the {\it end\/} of the list of returned values, they {\it changed\/}
the order from the one specified by \cltl, so that their new value is
the second value returned, and what should be second is now fourth.
Thanks, Franz!

@l
(defun reorder-env-information (fn)
  (lambda (&rest args)
    (multiple-value-bind (type locative declarations local)
        (apply fn args)
      (declare (ignore locative))
      (values type local declarations))))

#+allegro
(setf (symbol-function 'variable-information)
      (reorder-env-information #'sys:variable-information)
      (symbol-function 'function-information)
      (reorder-env-information #'sys:function-information))

@ The main entry point for the walker is |walk-form|. The walk stops after
walking an atomic or special form; otherwise, we keep walking until the
form no longer macroexpands.

@l
(defmethod walk-form ((walker walker) form &optional env &aux
                      (env (ensure-portable-walking-environment env))
                      (expanded t))
  (flet ((symbol-macro-p (form env)
           (and (symbolp form)
                (eql (variable-information form env) ':symbol-macro))))
    (loop
      (cond ((symbol-macro-p form env)) ; wait for macro expansion
            ((atom form)
             (return (walk-atomic-form walker form env)))
            ((not (symbolp (car form)))
             (return (walk-list walker form env)))
            ((or (not expanded)
                 (walk-as-special-form-p walker (car form) form env))
             (return (walk-compound-form walker (car form) form env))))
      (multiple-value-setq (form expanded)
        (macroexpand-for-walk walker form env)))))

@ @<Walker generic functions@>=
(defgeneric walk-form (walker form &optional env))

@ The walker will treat a form as a special form if and only if
|walk-as-special-form-p| returns true of that form.

@l
(defmethod walk-as-special-form-p (walker car form env)
  (declare (ignore walker car form env))
  nil)

@ @<Walker generic functions@>=
(defgeneric walk-as-special-form-p (walker car form env))

@ Macroexpansion and environment augmentation both get wrapped in generic
functions to allow subclasses to override the usual behavior.

@ @<Walker generic functions@>=
(defgeneric macroexpand-for-walk (walker form env))
(defgeneric augment-walker-environment (walker env &rest args))

@ The default methods for |macroexpand-for-walk| and
|augment-waker-environment| just call down to the normal Lisp
functions.

@l
(defmethod macroexpand-for-walk ((walker walker) form env)
  (macroexpand-1 form env))

(defmethod augment-walker-environment ((walker walker) env &rest args)
  (apply #'augment-environment env args))

@ Here's a utility function we'll use often in walker methods: it walks
each element of the supplied list and returns a new list of the results
of those walks.

@l
(defun walk-list (walker list env)
  (do ((form list (cdr form))
       (newform () (cons (walk-form walker (car form) env) newform)))
      ((atom form) (nreconc newform form))))

@ The functions |walk-atomic-form| and |walk-compound-form| are the
real work-horses of the walker. The former takes a walker instance,
an (atomic) form, an environment, and a flag indicating whether or
not the form occurs in an evaluated position. Compound forms, being
always evaluated, don't need such a flag, but we do provide an
additional |car| argument so that we can use |eql|-specializers.

@<Walker generic functions@>=
(defgeneric walk-atomic-form (walker form env &optional evalp))
(defgeneric walk-compound-form (walker car form env))

@ The default method for |walk-atomic-form| simply returns the form.
Note that this function won't be called for symbol macros; those are
expanded in |walk-form|.

@l
(defmethod walk-atomic-form ((walker walker) form env &optional (evalp t))
  (declare (ignore env evalp))
  form)

@ The default method for |walk-compound-form| is used for all funcall-like
forms; it leaves its |car| unevaluated and walks its |cdr|.

@l
(defmethod walk-compound-form ((walker walker) car form env)
  (declare (ignore car))
  `(,(walk-atomic-form walker (car form) env nil)
    ,@(walk-list walker (cdr form) env)))

@ There's a special walker function just for function names, since
they're not necessarily atomic.

@<Walker generic functions@>=
(defgeneric walk-function-name (walker function-name env))

@ Common Lisp defines a {\it function name\/} as ``A symbol or a list
|(setf symbol)|.'' We signal an continuable error in case of a malformed
function name.

@l
(defmethod walk-function-name ((walker walker) function-name env)
  (typecase function-name
    (symbol
     (walk-atomic-form walker function-name env nil))
    ((cons (eql setf) (cons symbol null))
     `(setf ,(walk-atomic-form walker (cadr function-name) env nil)))
    (t (cerror "Use the function name anyway."
               'invalid-function-name :name function-name)
       function-name)))

@ @<Condition classes@>=
(define-condition invalid-function-name (parse-error)
  ((name :initarg :name :reader function-name))
  (:report (lambda (error stream)
             (format stream "~@<Invalid function name ~A.~:@>" @+
                     (function-name error)))))

@t@l
(deftest (walk-function-name 1)
  (equal (walk-function-name (make-instance 'walker) 'foo nil)
         'foo)
  t)

(deftest (walk-function-name 2)
  (equal (walk-function-name (make-instance 'walker) '(setf foo) nil)
         '(setf foo))
  t)

(deftest (walk-function-name 3)
  (let ((error-handled nil))
    (flet ((note-and-continue (condition)
             (setq error-handled t)
             (continue condition)))
      (handler-bind ((invalid-function-name #'note-and-continue))
        (values (equal (walk-function-name (make-instance 'walker) @+
                                           '(foo bar) nil)
                       '(foo bar))
                error-handled))))
  t t)

@ Many of the special forms defined in Common Lisp can be walked using the
default method for |walk-compound-form| just defined, since their syntax is
the same as an ordinary function call. But it's important to override
|walk-as-special-form-p| for these operators, because ``[a]n
implmementation is free to implement a Common Lisp special operator as a
macro.'' (\csc{ansi} Common Lisp, section~3.1.2.1.2.2)

@l
(macrolet ((walk-as-special-form (operator)
             `(defmethod walk-as-special-form-p
                  ((walker walker) (car (eql ',operator)) form env)
                (declare (ignore form env))
                t)))
  (walk-as-special-form catch)
  (walk-as-special-form if)
  (walk-as-special-form load-time-value)
  (walk-as-special-form multiple-value-call)
  (walk-as-special-form multiple-value-prog1)
  (walk-as-special-form progn)
  (walk-as-special-form progv)
  (walk-as-special-form setq)
  (walk-as-special-form tagbody)
  (walk-as-special-form throw)
  (walk-as-special-form unwind-protect))

@ The rest of the special form walkers we define will need specialized
methods for both |walk-as-special-form-p| and |walk-compound-form|.
The following macro makes sure that these are consistently defined.

@l
(defmacro define-special-form-walker (operator (walker form env &rest rest) @+
                                      &body body &aux
                                      (car `(car (eql ',operator))))
  (flet ((arg-name (arg) (if (consp arg) (car arg) arg)))
    `(progn
       (defmethod walk-as-special-form-p (,walker ,car ,form ,env)
         (declare (ignorable ,@(mapcar #'arg-name `(,walker ,form ,env))))
         t)
       (defmethod walk-compound-form (,walker ,car ,form ,env ,@rest)
         (declare (ignorable ,@(mapcar #'arg-name `(,walker ,form ,env))))
         ,@body))))

@ Block-like special forms have a |cdr| that begins with a single
unevaluated form, followed by zero or more evaluated forms.

@l
(macrolet ((define-block-like-walker (operator)
             `(define-special-form-walker ,operator ((walker walker) form env)
                `(,(car form)
                  ,(walk-atomic-form walker (cadr form) env nil)
                  ,@(walk-list walker (cddr form) env)))))
  (define-block-like-walker block)
  (define-block-like-walker eval-when)
  (define-block-like-walker return-from)
  (define-block-like-walker the))

@ Quote-like special forms are entirely unevaluated.

@l
(macrolet ((define-quote-like-walker (operator)
             `(define-special-form-walker ,operator ((walker walker) form env)
                (declare (ignore walker env))
                form)))
  (define-quote-like-walker quote)
  (define-quote-like-walker go))

@ The |function| special form takes either a valid function name or a
lambda expression.

@l
(define-special-form-walker function ((walker walker) form env)
  `(,(car form)
    ,(if (and (consp (cadr form))
              (eql (caadr form) 'lambda))
         (walk-lambda-expression walker (cadr form) env)
         (walk-function-name walker (cadr form) env))))

@t@l
(deftest (walk-function 1)
  (tree-equal
   (walk-form (make-instance 'walker) '(function foo) nil)
   '(function foo))
  t)

(deftest (walk-function 2)
  (tree-equal
   (walk-form (make-instance 'walker) '(function (setf foo)) nil)
   '(function (setf foo)))
  t)

(deftest (walk-function 3)
  (tree-equal
   (walk-form (make-instance 'walker) '(function (lambda (x) x)) nil)
   '(function (lambda (x) x)))
  t)

@ Next, we'll work our way up to parsing \L~expressions and other
function-defining forms.

Given a sequence of declarations and possibly a documentation string
followed by other forms (as occurs in the bodies of |defun|, |defmacro|,
\etc.), |parse-body| returns |(values forms decls doc)|, where |decls|
is the declaration specifiers found in each |declare| expression, |doc|
holds a doc string (or |nil| if there is none), and |forms| holds the
other forms. See \csc{ansi} Common Lisp section~3.4.11 for the rules on
the syntactic interaction of doc strings and declarations.

If |doc-string-allowed| is |nil| (the default), then no forms will be
treated as documentation strings.

@l
(defun parse-body (body &key doc-string-allowed walker env &aux doc)
  (flet ((doc-string-p (x remaining-forms)
           (and (stringp x) doc-string-allowed remaining-forms (null doc)))
         (declaration-p (x)
           (and (listp x) (eql (car x) 'declare))))
    (loop for forms = body then (cdr forms)
          as x = (car forms)
          while forms
          if (doc-string-p x (cdr forms)) do (setq doc x)
          else if (declaration-p x) append (cdr x) into decls
               else do (loop-finish)
          finally (return (values forms
                                  (if walker
                                      (walk-declaration-specifiers @+
                                       walker decls env)
                                      decls)
                                  doc)))))

@t@l
(deftest (parse-body 1)
  (parse-body '("doc" (declare (optimize speed)) :foo :bar)
              :doc-string-allowed t)
  (:foo :bar)
  ((optimize speed))
  "doc")

(deftest (parse-body 2)
  (parse-body '((declare (optimize speed))
                "doc"
                (declare (optimize space))
                :foo :bar)
              :doc-string-allowed t)
  (:foo :bar)
  ((optimize speed) (optimize space))
  "doc")

(deftest (parse-body 3)
  (parse-body '("doc" "string") :doc-string-allowed t)
  ("string")
  nil
  "doc")

(deftest (parse-body 4)
  (parse-body '((declare (optimize debug)) "string") :doc-string-allowed t)
  ("string")
  ((optimize debug))
  nil)

(deftest (parse-body 5)
  (parse-body '((declare (optimize debug)) "string") :doc-string-allowed nil)
  ("string")
  ((optimize debug))
  nil)

@ Declaration forms aren't evaluated in Common Lisp, but we'll want to be
able to walk the specifiers.

@<Walker generic functions@>=
(defgeneric walk-declaration-specifiers (walker decls env))

@ @l
(defmethod walk-declaration-specifiers ((walker walker) decls env)
  (declare (ignore env))
  decls)

@ The syntax of \L-lists is given in section~3.4 of the \csc{ansi} standard.
We accept the syntax of macro \L-lists, since they are the most general,
and appear to be a superset of every other type of \L-list.

This function returns two values: the walked \L-list and a new environment
object containing bindings for all of the parameters found therein.

@l
(defun walk-lambda-list (walker lambda-list decls env &aux
                         new-lambda-list (state :reqvars))
  (labels ((augment-env (&rest vars &aux (vars (remove-if #'null vars)))
             (setq env (augment-walker-environment walker env
                                                   :variable vars
                                                   :declare decls)))
           (update-state (keyword)
             (setq state (ecase keyword
                           ((nil) state)
                           (&optional :optvars)
                           ((&rest &body) :restvar)
                           (&key :keyvars)
                           (&aux :auxvars)
                           (&environment :envvar))))
           (maybe-destructure (var/pattern)
             (if (consp var/pattern)
                 (walk-lambda-list walker var/pattern decls env)
                 (values var/pattern (augment-env var/pattern)))))
    @<Check for |&whole| and |&environment| vars, and augment the lexical
      environment with them if found@>
    (do* ((lambda-list lambda-list (cdr lambda-list))
          (arg (car lambda-list) (car lambda-list)))
         ((null lambda-list) (values (nreverse new-lambda-list) env))
      (ecase state
        (:envvar @<Process |arg| as an environment parameter@>)
        ((:reqvars :restvar) ; required and rest parameters have the same syntax
         @<Process |arg| as a required parameter@>)
        (:optvars @<Process |arg| as an optional parameter@>)
        (:keyvars @<Process |arg| as a keyword parameter@>)
        (:auxvars @<Process |arg| as an auxiliary variable@>))
      (when (and (cdr lambda-list) (atom (cdr lambda-list)))
        @<Process dotted rest var@>))))

@ A |&whole| variable must come first in a \L-list, and an |&environment|
variable, although it may appear anywhere in the list, must be bound along
with |&whole|. We'll pop a |&whole| variable off the front of |lambda-list|,
but we'll leave any |&environment| variable to be picked up later.

@<Check for |&whole| and |&environment|...@>=
(let ((wholevar (and (consp lambda-list)
                     (eql (car lambda-list) '&whole)
                     (push (pop lambda-list) new-lambda-list)
                     (car (push (pop lambda-list) new-lambda-list))))
      (envvar (do ((lambda-list lambda-list (cdr lambda-list)))
                  ((atom lambda-list) nil)
                (when (eql (car lambda-list) '&environment)
                  (return (cadr lambda-list))))))
  (augment-env wholevar envvar))

@ We've already added the environment variable to our lexical environment,
so we just push it onto the new \L-list and prepare for the next parameter.

@<Process |arg| as an environment parameter@>=
(push (pop lambda-list) new-lambda-list)
(update-state (car lambda-list))

@ @<Process |arg| as a required parameter@>=
(etypecase arg
  (symbol @<Process the symbol in |arg| as a parameter@>)
  (cons
   (multiple-value-bind (pattern new-env)
       (walk-lambda-list walker arg decls env)
     (setq env new-env)
     (push pattern new-lambda-list))))

@ Watch the order here: in the non-simple-|var| case, both the init
form and the pattern (if any) need to be walked in an environment
{\it unaugmented} with any supplied-p-parameter.

@<Process |arg| as an optional parameter@>=
(etypecase arg
  (symbol @<Process the symbol...@>)
  (cons
   (destructuring-bind (var/pattern &optional init-form supplied-p-parameter) @+
       arg
     (when init-form
       (setq init-form (walk-form walker init-form env)))
     (multiple-value-setq (var/pattern env)
       (maybe-destructure var/pattern))
     (when supplied-p-parameter
       (augment-env supplied-p-parameter))
     (push (nconc (list var/pattern)
                  (and init-form (list init-form))
                  (and supplied-p-parameter (list supplied-p-parameter)))
           new-lambda-list))))

@ @<Process |arg| as a keyword parameter@>=
(cond ((eql arg '&allow-other-keys)
       (push (pop lambda-list) new-lambda-list)
       (update-state (car lambda-list)))
      (t
       (etypecase arg
         (symbol @<Process the symbol in |arg| as a parameter@>)
         (cons
          (destructuring-bind (var/kv &optional init-form supplied-p-parameter) arg
            (when init-form
              (setq init-form (walk-form walker init-form env)))
            (if (consp var/kv)
                (destructuring-bind (keyword-name var/pattern) var/kv
                  (multiple-value-setq (var/pattern env)
                    (maybe-destructure var/pattern))
                  (setq var/kv (list keyword-name var/pattern)))
                (augment-env var/kv))
            (when supplied-p-parameter
              (augment-env supplied-p-parameter))
            (push (nconc (list var/kv)
                         (and init-form (list init-form))
                         (and supplied-p-parameter (list supplied-p-parameter)))
                  new-lambda-list))))))

@ @<Process |arg| as an auxiliary variable@>=
(etypecase arg
  (symbol @<Process the symbol...@>)
  (cons
   (destructuring-bind (var &optional init-form) arg
     (when init-form
       (setq init-form (walk-form walker init-form env)))
     (augment-env var)
     (push (nconc (list var)
                  (and init-form (list init-form)))
           new-lambda-list))))

@ @<Process the symbol in |arg| as a parameter@>=
(cond ((member arg lambda-list-keywords)
       (push arg new-lambda-list)
       (update-state arg))
      (t (augment-env arg)
         (push arg new-lambda-list)))

@ We normalize a dotted rest parameter into a proper |&rest| parameter
to avoid having to worry about reversing an improper |new-lambda-list|.

@<Process dotted rest var@>=
(let ((var (cdr lambda-list)))
  (augment-env var)
  (push '&rest new-lambda-list)
  (push (cdr lambda-list) new-lambda-list))
(setq lambda-list nil) ; walk no more

@t@l
(deftest walk-ordinary-lambda-list
  (let ((walker (make-instance 'walker))
        (lambda-list '(x y &optional (o (+ x y)) &key ((:k k) 2 k-supplied-p)
                       &rest args &aux w (z (if k-supplied-p o x))))
        (decls '((special x)))
        (env (ensure-portable-walking-environment nil)))
    (multiple-value-bind (new-lambda-list new-env)
        (walk-lambda-list walker lambda-list decls env)
      (values (tree-equal lambda-list new-lambda-list)
              (variable-information 'x new-env)
              (every (lambda (x) (eql x ':lexical))
                     (mapcar (lambda (sym) (variable-information sym new-env))
                             '(y z o k k-supplied-p args w z))))))
  t :special t)

(deftest walk-macro-lambda-list
  (let ((walker (make-instance 'walker))
        (lambda-list '(&whole w (x y) &optional ((o) (+ x y))
                       &key ((:k (k1 k2)) (2 3) k-supplied-p)
                       &environment env))
        (env (ensure-portable-walking-environment nil)))
    (multiple-value-bind (new-lambda-list new-env)
        (walk-lambda-list walker lambda-list nil env)
      (values (tree-equal lambda-list new-lambda-list)
              (every (lambda (x) (eql x ':lexical))
                     (mapcar (lambda (sym) (variable-information sym new-env))
                             '(w x y o k1 k2 k-supplied-p env))))))
  t t)

(deftest walk-dotted-macro-lambda-list
  (let ((walker (make-instance 'walker))
        (lambda-list '(a b . c))
        (env (ensure-portable-walking-environment nil)))
    (multiple-value-bind (new-lambda-list new-env)
        (walk-lambda-list walker lambda-list nil env)
      (values (tree-equal (subst '(&rest c) 'c lambda-list) new-lambda-list)
              (every (lambda (x) (eql x ':lexical))
                     (mapcar (lambda (sym) (variable-information sym new-env))
                             '(a b c))))))
  t t)

@ Having built up the necessary machinery, walking a \L-expression is now
straightforward. The slight generality of walking the car of the form using
|walk-function-name| is because this function will also be used to walk the
bindings in |flet|, |macrolet|, and~|labels| special forms.

@l
(defun walk-lambda-expression (walker form env &aux
                               (lambda-list (cadr form)) (body (cddr form)))
  (multiple-value-bind (forms decls doc) @+
      (parse-body body :walker walker :env env :doc-string-allowed t)
    (multiple-value-bind (lambda-list env) @+
        (walk-lambda-list walker lambda-list decls env)
      `(,(walk-function-name walker (car form) env)
        ,lambda-list
        ,@(if doc `(,doc))
        ,@(if decls `((declare ,@decls)))
        ,@(walk-list walker forms env)))))

@ `lambda' is not a special operator in Common Lisp, but we'll treat
\L-expressions as special forms.

@l
(define-special-form-walker lambda ((walker walker) form env)
  (walk-lambda-expression walker form env))

@ We come now to the binding special forms. The six binding special
forms in Common Lisp (|let|, |let*|, |flet|, |labels|, |macrolet|, and
|symbol-macrolet|) all have essentially the same syntax; only the scope
and namespace of the bindings differ.

@t To test the walker on binding forms, we'll use a specialized walker
class that recognizes a custom |binding| special form. Its syntax is
|(binding symbol namespace)|, where |symbol| is an unevaluated symbol,
and |namespace| is one of |:function| or~|:variable|. The walker function
signals a |binding| condition, which includes the symbol, the requested
namespace, and the current lexical environment, which a handler can then
extract and record. If the handler declines to handle the condition,
the function simply returns |symbol|.

@l
(define-condition binding (condition)
  ((symbol :initarg :symbol :reader binding-symbol)
   (namespace :initarg :namespace :reader binding-namespace)
   (environment :initarg :environment :reader binding-environment)))

(defclass test-walker (walker) ())

(define-special-form-walker binding ((walker test-walker) form env)
  (destructuring-bind (symbol namespace) (cdr form)
    (signal 'binding :symbol symbol :namespace namespace :environment env)
    (walk-form walker symbol env)))

(defmacro define-walk-binding-test (name form walked-form binding-info)
  `(deftest ,name
     (let (bindings)
       (flet ((note-binding (binding &aux
                             (symbol (binding-symbol binding))
                             (env (binding-environment binding)))
                (push (case (binding-namespace binding)
                        (:function (function-information symbol env))
                        (:variable (variable-information symbol env)))
                      bindings)))
         (handler-bind ((binding #'note-binding))
           (values (tree-equal (walk-form (make-instance 'test-walker) ',form)
                               ',walked-form)
                   (nreverse bindings)))))
     t
     ,binding-info))

@ We'll start with two little utility routines. The first walks a
variable-like binding form (e.g., the |cadr| of a |let|/|let*| or
|symbol-macrolet| form). It normalizes atomic binding forms to
conses in order to avoid needing special-cases in the actual walker
methods.

The function-like binding forms will use |walk-lambda-expression| for
the same purpose.

@l
(defun walk-variable-binding (walker p env &aux @+
                              (binding (if (consp p) p (list p))))
  (list (walk-atomic-form walker (car binding) env nil)
        (and (cdr binding)
             (walk-form walker (cadr binding) env))))

@ The second helper function just builds the |macro| argument to
|augment-walker-environment| for the |macrolet| walker.

@l
(defun make-macro-definitions (walker defs env)
  (mapcar (lambda (def &aux (name (walk-atomic-form walker (car def) env nil)))
            (list name
                  (enclose (parse-macro name (cadr def) (cddr def) env)
                           env walker)))
          defs))

@ |let|, |flet|, |macrolet|, and |symbol-macrolet| are all parallel binding
forms: they walk their bindings in an unaugmented environment, then execute
their body forms in an environment that contains all of new the bindings.

@l
(define-special-form-walker let
    ((walker walker) form env &aux
     (bindings (mapcar (lambda (p)
                         (walk-variable-binding walker p env))
                       (cadr form)))
     (body (cddr form)))
  (multiple-value-bind (forms decls) (parse-body body :walker walker :env env)
    `(,(car form)
      ,bindings
      ,@(if decls `((declare ,@decls)))
      ,@(walk-list walker forms
                   (augment-walker-environment walker env
                                               :variable (mapcar #'car bindings)
                                               :declare decls)))))

(define-special-form-walker flet
    ((walker walker) form env &aux
     (bindings (mapcar (lambda (p)
                         (walk-lambda-expression walker p env))
                       (cadr form)))
     (body (cddr form)))
  (multiple-value-bind (forms decls) (parse-body body :walker walker :env env)
    `(,(car form)
      ,bindings
      ,@(if decls `((declare ,@decls)))
      ,@(walk-list walker forms
                   (augment-walker-environment walker env
                                               :function (mapcar #'car bindings)
                                               :declare decls)))))

(define-special-form-walker macrolet
    ((walker walker) form env &aux
     (bindings (mapcar (lambda (p)
                         (walk-lambda-expression walker p env))
                       (cadr form)))
     (body (cddr form))
     (macros (make-macro-definitions walker bindings env)))
  (multiple-value-bind (forms decls)
      (parse-body body :walker walker :env env)
    `(,(car form)
      ,bindings
      ,@(if decls `((declare ,@decls)))
      ,@(walk-list walker forms
                   (augment-walker-environment walker env
                                               :macro macros
                                               :declare decls)))))

(define-special-form-walker symbol-macrolet
    ((walker walker) form env &aux
     (bindings (mapcar (lambda (p)
                         (walk-variable-binding walker p env))
                       (cadr form)))
     (body (cddr form)))
  (multiple-value-bind (forms decls)
      (parse-body body :walker walker :env env)
    `(,(car form)
      ,bindings
      ,@(if decls `((declare ,@decls)))
      ,@(walk-list walker forms
                   (augment-walker-environment walker env
                                               :symbol-macro bindings
                                               :declare decls)))))

@t@l
(define-walk-binding-test walk-let
  (let ((x 1)
        (y (binding x :variable)))
    (declare (special x))
    (binding y :variable))
  (let ((x 1) (y x)) (declare (special x)) y)
  (nil :lexical))

(define-walk-binding-test walk-flet
  (flet ((foo (x) (binding x :variable))
         (bar (y) (binding foo :function)))
    (declare (special x))
    (binding foo :function))
  (flet ((foo (x) x)
         (bar (y) foo))
    (declare (special x))
    foo)
  (:lexical nil :function))

(define-walk-binding-test walk-macrolet
  (macrolet ((foo (x) `,x)
             (bar (y) `,y))
    (binding foo :function)
    (foo :foo))
  (macrolet ((foo (x) x)
             (bar (y) y))
    foo
    :foo)
  (:macro))

(define-walk-binding-test walk-symbol-macrolet
  (symbol-macrolet ((foo :foo)
                    (bar :bar))
    (binding foo :variable)
    (binding bar :variable)
    (binding foo :function))
  (symbol-macrolet ((foo :foo)
                    (bar :bar))
    :foo :bar :foo)
  (:symbol-macro :symbol-macro nil))

@ The two outliers are |let*|, which augments its environment sequentially,
and |labels|, which does so before walking any of its bindings.

@l
(define-special-form-walker let*
    ((walker walker) form env &aux (bindings (cadr form)) (body (cddr form)))
  (multiple-value-bind (forms decls)
      (parse-body body :walker walker :env env)
    `(,(car form)
      ,(mapcar (lambda (p)
                 (let ((walked-binding (walk-variable-binding walker p env)))
                   (setq env (augment-walker-environment
                               walker env
                               :variable (list (car walked-binding))
                               :declare decls))
                   walked-binding))
               bindings)
      ,@(if decls `((declare ,@decls)))
      ,@(walk-list walker forms env))))

(define-special-form-walker labels
    ((walker walker) form env &aux (bindings (cadr form)) (body (cddr form)))
  (multiple-value-bind (forms decls)
      (parse-body body :walker walker :env env)
    (let* ((function-names (mapcar (lambda (p)
                                     (walk-function-name walker (car p) env))
                                   bindings))
           (env (augment-walker-environment walker env
                                            :function function-names
                                            :declare decls)))
      `(,(car form)
        ,(mapcar (lambda (p) (walk-lambda-expression walker p env)) bindings)
        ,@(if decls `((declare ,@decls)))
        ,@(walk-list walker forms env)))))

@t@l
(define-walk-binding-test walk-let*
  (let* ((x 1)
         (y (binding x :variable)))
    (declare (special x))
    (binding y :variable))
  (let* ((x 1) (y x)) (declare (special x)) y)
  (:special :lexical))

(define-walk-binding-test walk-labels
  (labels ((foo (x) (binding x :variable))
           (bar (y) (binding foo :function)))
    (declare (special x))
    (binding foo :function))
  (labels ((foo (x) x)
           (bar (y) foo))
    (declare (special x))
    foo)
  (:lexical :function :function))

@ The last special form we need a specialized walker for is |locally|,
which simply executes its body in a lexical environment augmented by a
set of declarations.

@l
(define-special-form-walker locally ((walker walker) form env)
  (multiple-value-bind (forms decls)
      (parse-body (cdr form) :walker walker :env env)
    `(,(car form)
      ,@(if decls `((declare ,@decls)))
      ,@(walk-list walker forms
                   (augment-walker-environment walker env :declare decls)))))

@t@l
(define-walk-binding-test walk-locally
  (let ((y t))
    (list (binding y :variable)
          (locally (declare (special y))
            (binding y :variable))))
  (let ((y t)) (list y (locally (declare (special y)) y)))
  (:lexical :special))

@t Here's a simple walker mix-in class that allows easy tracing of a walk.
It's only here for debugging purposes; it's not a superclass of any of
the walker classes defined in this program.

@l
(defclass tracing-walker (walker) ())

(defmethod walk-atomic-form :before
    ((walker tracing-walker) form env &optional (evalp t))
  (format t "; walking ~:[un~;~]evaluated atomic form ~S~@[ (~(~A~) variable)~]~%"
          evalp form (and (symbolp form) (variable-information form env))))

(defmethod walk-compound-form :before ((walker tracing-walker) car form env)
  (declare (ignore car env))
  (format t "~<; ~@;walking compound form ~W~:>~%" (list form)))

@*Indexing. Having built up our code walker, we can now use it to produce
an index of the interesting symbols in a web. We'll say a symbol is
{\it interesting\/} if it is interned in one of the packages listed in
|*index-packages*|. The user can manually add packages to this list using
\.{@@e} forms, but that should be unecessay in most cases, since we'll
automatically add all packages that are defined in the web being processed.
{\it FIXME\/}: This isn't true yet.

@<Global variables@>=
(defvar *index-packages* nil)

@ @<Initialize global...@>=
;FIXME: (setq *index-packages* nil)

@ Before we proceed, let's establish some terminology. Some of these
terms have already been used informally, but it's best to nail down
their meanings. Formally, an {\it index\/} is an ordered collection of
{\it entries}, each of which is a (\metasyn{heading}, \metasyn{locator})
pair: the {\it locator} indicates where the object referred to by the
{\it heading} may be found.

Headings may in general be multi-leveled. For example, in the entries
we generate via the code walk below, the headings will always be of the
form (\metasyn{name}, \metasyn{kind}), where {\it kind\/} is a symbol
representing an abstract namespace like `local function' or `special
variable'.

In this program, headings are represented by designators for lists of
string designators, and are sorted lexicographically.

@l
(defun entry-heading-lessp (h1 h2 &aux
                            (h1 (if (listp h1) h1 (list h1)))
                            (h2 (if (listp h2) h2 (list h2))))
  (or (and (null h1) h2)
      (string-lessp (string (car h1)) (string (car h2)))
      (and (string-equal (string (car h1)) (string (car h2)))
           (cdr h2)
           (entry-heading-lessp (cdr h1) (cdr h2)))))

@t@l
(deftest entry-heading-lessp
  (notany #'not
          (list (not (entry-heading-lessp 'a 'a))
                (entry-heading-lessp 'a 'b)
                (entry-heading-lessp 'a '(a x))
                (entry-heading-lessp '(a x) '(a y))
                (entry-heading-lessp '(a x) '(b x))
                (entry-heading-lessp '(a y) '(b x))
                (entry-heading-lessp '(a x) '(b y))))
  t)

@ A locator is either a section (the usual case) or a cross-reference to
another index entry. We'll represent locators as instances of a |locator|
class, and use a single generic function, |location|, to dereference them.

Section locators have an additional slot for a definition flag, which
when true indicates that the object referred to by the associated heading
is defined, and not just used, in the section represented by that locator.
Such locators will be given a bit of typographic emphasis by the weaver
when it prints the containing entry.

@l
(defclass locator () ())

(defclass section-locator (locator)
  ((section :accessor location :initarg :section)
   (defp :accessor locator-definition-p :initarg :defp)))

(defclass xref-locator (locator)
  ((heading :accessor location :initarg :heading)))
(defclass see-locator (xref-locator) ())
(defclass see-also-locator (xref-locator) ())

@ @l
(defun make-locator (&key section defp see see-also)
  (cond (section (make-instance 'section-locator :section section :defp defp))
        (see (make-instance 'see-locator :heading see))
        (see-also (make-instance 'see-locator :heading see-also))))

@ Since we'll eventually want the index sorted by heading, we'll store
the entries in a binary search tree. To simplify processing, what we'll
actually store is {\it entry lists}, which are collections of entries
with identical headings, but we'll overload the term in what seems to be
a fairly traditional manner and call them entries, too.

@l
(defclass index-entry (binary-search-tree)
  ((key :accessor entry-heading)
   (locators :accessor entry-locators :initarg :locators :initform '())))

(defmethod find-or-insert (item (root index-entry) &key
                           (predicate #'entry-heading-lessp)
                           (test #'equalp)
                           (insert-if-not-found t))
  (call-next-method item root
                    :predicate predicate
                    :test test
                    :insert-if-not-found insert-if-not-found))

@ The entry trees get stored in |index| objects, for which we define the
following protocol functions.

@l
(defclass index ()
  ((entries :accessor index-entries :initform nil)))

(defun make-index () (make-instance 'index))
(defgeneric add-index-entry (index heading locator &key))
(defgeneric find-index-entries (index heading))

@ The following method adds an index entry for |heading| with location
|section|. A new locator is constructed only when necessary, and duplicate
locators are automatically suppressed. Definitional locators are also made
to supersede ordinary locators.

@l
(define-modify-macro orf (&rest args) or)

(defmethod add-index-entry ((index index) heading (section section) &key defp)
  (flet ((make-locator ()
           (make-locator :section section :defp defp)))
    (if (null (index-entries index))
        (setf (index-entries index)
              (make-instance 'index-entry @+
                             :key heading @+
                             :locators (list (make-locator))))
        (let* ((entry (find-or-insert heading (index-entries index)))
               (old-locator (find section (entry-locators entry) @+
                                  :key #'location)))
          (if old-locator
              (orf (locator-definition-p old-locator) defp)
              (push (make-locator) (entry-locators entry)))))))

@ |find-index-entries| returns a list of locators for all of the entries
with the given heading.

@l
(defmethod find-index-entries ((index index) heading)
  (let ((entries (index-entries index)))
    (when entries
      (multiple-value-bind (entry present-p)
          (find-or-insert heading entries :insert-if-not-found nil)
        (when present-p
          (entry-locators entry))))))

@t@l
(deftest (add-index-entry 1)
  (let ((index (make-index))
        (*sections* (make-array 1 :fill-pointer 0)))
    (add-index-entry index 'foo (make-instance 'section))
    (let ((locators (find-index-entries index 'foo)))
      (values (length locators)
              (section-number (location (first locators))))))
  1 0)

(deftest (add-index-entry 2)
  (let* ((index (make-index))
         (*sections* (make-array 1 :fill-pointer 0))
         (section (make-instance 'section)))
    (add-index-entry index 'foo section)
    (add-index-entry index 'foo section :defp t) ; def should replace use
    (locator-definition-p (first (find-index-entries index 'foo))))
  t)

(deftest (add-index-entry 3)
  (let ((index (make-index))
        (*sections* (make-array 3 :fill-pointer 0)))
    (add-index-entry index 'foo (make-instance 'section))
    (let ((section (make-instance 'section)))
      (add-index-entry index 'foo section)
      (add-index-entry index 'foo section :defp t))
    (add-index-entry index 'foo (make-instance 'section))
    (sort (mapcar #'section-number
                  (mapcar #'location (find-index-entries index 'foo)))
          #'<))
  (0 1 2))

@ The {\it kind} field in our entry headings will be keyword symbols that
denote the namespace into which {\it name} indexes. This little routine
creates such keywords from symbols whose names start with \.{"DEFINE-"}
or~\.{"DEF"}.

@l
(defun make-keyword-from-def (symbol)
  (values (intern (loop with name = (symbol-name symbol)
                        for prefix in '("define-" "def")
                        as n = (min (length prefix) (length name))
                        if (string-equal (subseq name 0 n) prefix)
                          do (return (subseq name n))
                        finally (warn "Non-defining symbol ~S" symbol)
                                (return name))
                  (find-package "KEYWORD"))))

@t@l
(deftest make-keyword-from-def
  (values (make-keyword-from-def 'define-foo)
          (make-keyword-from-def 'defbar)
          (handler-bind ((warning #'muffle-warning))
            (make-keyword-from-def 'baz)))
  :foo
  :bar
  :baz)

@ We'll perform the indexing by walking over the code of each section and
noting each of the interesting symbols that we find there according to its
semantic role. In theory, this should be a straightforward task for any
Common Lisp code walker. What makes it tricky is that references to named
sections can occur anywhere in a form, which might break the syntax of
macros and special forms unless we tangle the form first. But once we
tangle a form, we lose the provenance of the sub-forms that came from
named sections, and so our index would be wrong.

The trick that we use to overcome this problem is to tangle the forms in a
special way where instead of just splicing the named section code into
place, we instead make a special kind of copy of each form, and splice
those into place. Those copies will have each symbol replaced with an
uninterned symbol whose value cell contains the symbol it replaced and
whose |section| property contains the section in which that symbol occured.
We'll these uninterned symbols {\it referring symbols}.

First, we'll need a routine that does the substitution just described.

@l
(defun substitute-symbols (form section &aux symbols)
  (labels ((get-symbols (form)
             (cond ((and (symbolp form)
                         (member (symbol-package form) *index-packages*))
                    (pushnew form symbols))
                   ((atom form) nil)
                   (t (get-symbols (car form))
                      (get-symbols (cdr form))))))
    (get-symbols form)
    (sublis (map 'list
                 (lambda (sym)
                   (let ((refsym (make-symbol (symbol-name sym))))
                     (setf (symbol-value refsym) sym)
                     (setf (get refsym 'section) section)
                     (cons sym refsym)))
                 symbols)
            form)))

@ This next function goes the other way: given a symbol, it determines
whether it is a referring symbol, and if so, it returns the symbol referred
to and the section it came from. Otherwise, it just returns the given
symbol. This interface makes it convenient to use in a |multiple-value-bind|
form without having to apply a predicate first.

@l
(defun symbol-provenance (symbol)
  (let ((section (get symbol 'section)))
    (if (and (null (symbol-package symbol))
             (boundp symbol)
             section)
        (values (symbol-value symbol) section)
        symbol)))

@t@l
(deftest (symbol-provenance 1)
  (let ((*index-packages* (list (find-package "KEYWORD"))))
    (symbol-provenance (substitute-symbols ':foo 1)))
  :foo 1)

(deftest (symbol-provenance 2)
  (symbol-provenance :foo)
  :foo)

@ To get referring symbols in the tangled code, we'll use an |:around|
method on |section-code| that conditions on a special variable,
|*indexing*|, that we'll bind to true while we're tangling for the
purposes of indexing.

We can't feed the raw section code to |substitute-symbols|, since it's
not really Lisp code: it's full of markers and such. So we'll abuse the
tangler infrastructure and use it to do marker replacement, but {\it not\/}
named-section expansion.

@l
(defmethod section-code :around ((section section))
  (let ((code (call-next-method)))
    (if *indexing*
        (substitute-symbols (tangle code :expand-named-sections-p nil) section)
        code)))

@ @<Global variables@>=
(defvar *indexing* nil)

@ The top-level indexing routine will use this function to obtain the
completely tangled code with referring symbols, and {\it that}'s what
we'll walk.

@l
(defun tangle-code-for-indexing (sections)
  (let ((*indexing* t))
    (tangle (unnamed-section-code-parts sections))))

@ Now we'll define a specialized walker that does the actual indexing.

@l
(defclass indexing-walker (walker)
  ((index :accessor walker-index :initform (make-index))))

@ Walking general declaration expressions is difficult, mostly because of
the shorthand notation for type declarations. Fortunately, we only care
about |special| declarations for the purposes of indexing, so we just throw
everything else away.

@l
(defmethod walk-declaration-specifiers ((walker indexing-walker) decls env)
  (loop for (identifier . data) in decls
        if (eql identifier 'special)
          collect `(special ,@(walk-list walker data env))))

@t@l
(deftest (walk-declaration-specifiers indexing)
  (equal (walk-declaration-specifiers (make-instance 'indexing-walker)
                                      '((type foo x)
                                        (special x y z)
                                        (optmize debug))
                                      nil)
         '((special x y z)))
  t)

@ The only atoms we care about indexing are the symbols that referring
symbols refer to.

@l
(defmethod walk-atomic-form ((walker indexing-walker) form env &optional @+
                             (evalp t))
  (if (symbolp form)
      (multiple-value-bind (symbol section) (symbol-provenance form)
        (when section
          (if evalp
              (index-variable (walker-index walker) symbol section env)
              (index-function (walker-index walker) symbol section env)))
        symbol)
      form))

@ We don't currently index lexical variables, as that would probably just
bulk up the index to no particular advantage.

@l
(defun index-variable (index variable section env &optional defp)
  (multiple-value-bind (type local) (variable-information variable env)
    (when (member type '(:special :symbol-macro :constant))
      (add-index-entry index
                       (list variable
                             (ecase type
                               (:special ':special-variable)
                               (:symbol-macro @+
                                (if local ':local-symbol-macro ':symbol-macro))
                               (:constant ':constant)))
                       section
                       :defp defp))))

(defun index-function (index function section env &optional defp)
  (multiple-value-bind (type local) (function-information function env)
    (when (member type '(:function :macro))
      (add-index-entry index
                       (list function
                             (ecase type
                               (:function @+
                                (if local ':local-function ':function))
                               (:macro (if local ':local-macro ':macro))))
                       section
                       :defp defp))))

@ And here, finally, is the top-level indexing routine: it walks the
tangled, symbol-replaced code of the given sections and returns an index
of all of the interesting symbols so encountered.

@l
(defun index-sections (sections &key (walker (make-instance 'indexing-walker)))
  (dolist (form (tangle-code-for-indexing sections) (walker-index walker))
    (walk-form walker form)))
