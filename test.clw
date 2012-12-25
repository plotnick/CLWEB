% Some limbo text.
@*Initialization.
@l
@e
(defpackage "TEST" (:use "COMMON-LISP"))
@e
(in-package "TEST")

@*Foo. The function |foo| adds twice its argument's value to thrice it.
@l
(defun foo (x)
  "The function FOO takes an integer X, and returns the sum of X doubled
and X trebled."
  (+ @<Twice |x|@> @<Thrice |x|@>))

@ @<The only even prime@>=2
@ @<Twice |x|@>=(* x @<The only...@>)
@ @<Thrice...@>=(* x 3)

@*Bar. The function |bar| returns the first four natural numbers (including 0),
and demonstrates how a named section may be defined piecewise.
@l
(defun bar () '(@<Natural numbers@>))

@ @<Natural...@>=0
@ @<Natural...@>=1
@ @<Natural...@>=@<The only even...@>
@ @<Natural...@>=3

@ Here's a form that uses a named section that contains multiple forms
which should be spliced into place.

@l
(defvar *sum*
  (@<Put the first three natural numbers in |a|, |b|, and |c|@>
    (+ a b c)))

@ @<Put the first three...@>=
destructuring-bind (a b c &rest args) (bar) (declare (ignore args))

@ Here's a section with no code. None at all. Not even a scrap. It exists
just so that we can make sure that in such an eventuality, everything is
copacetic.

@ This section is just here to use the next one.
@l
@<The next section@>

@ And this section is just to be used by the previous one. The |defun| should
be all on one line.
@<The next...@>=
(defun do-some-stuff () ;
  (list 'some 'stuff))

@ And this one gets used by no one at all.
@<Unused section@>=nil
@ Also unused, but with the same name as the last one.
@<Unused section@>=()
@ And one more, with a different name.
@<Another unused section@>=t

@*Markers. Here we test out some of the trickier markers.

@l
(defparameter *cons* '(a . b))
(defparameter *vector* #5(a b c))
(defparameter *bit-vector* #8*1011 "An octet")
(defparameter *bit-string* #B1011)
(defparameter *deadbeef* #Xdeadbeef)
(defparameter *list* '#.(list 1 2 (let ((x 1)) @<Thrice |x|@>)))
(defparameter *impl* #+sbcl "SBCL" #+(not sbcl) "Not SBCL")

@*Baz. The sole purpose of this section is to exercise some of the
pretty-printing capabilities of |weave|. Note that in inner-Lisp mode,
newlines and such are ignored:
|(defun foo (bar baz)
   (baz (apply #'qux bar)))|

@l
(defun read-stuff-from-file (file &key direction)
  (with-open-file (stream file :direction direction)
    (loop for x = (read stream nil nil nil) ; |x| is a loop-local variable
          while x collect x)))

;;; The next function doesn't really do anything very interesting, it
;;; just contains some examples of how various Common Lisp forms are
;;; usually indented. And this long, pointless comment is just here to
;;; span multiple lines at the top-level.
(defun body-forms ()
  (flet ((lessp (x y)
           (< x
              y))
         (three-values ()
           (values 1 2 3)))
    ;; This multi-line comment is here only to span multiple lines,
    ;; like the one just before the start of this |defun|, only not
    ;; at the top-level.
    (multiple-value-bind (a
                          b
                          c)
        (three-values)
      (foo a)
      (lessp b c))))

(defmacro backq-forms (foo bar list &aux (var (gensym)))
  `(dolist (,var ,list ,list)
     (funcall ,foo ,@bar ,var)))

(defun list-length-example (x)
  (do ((n 0 (+ n 2))
       (fast x (cddr fast))
       (slow x (cdr slow)))
      (nil)
    (when (endp fast) (return n))
    (when (endp (cdr fast)) (return (+ n 1)))
    (when (and (eq fast slow) (> n 0)) (return nil))))

@ @l
"Here's a top-level string
split over two lines."

@ Read-time conditionals are also tricky, especially when they span
multiple lines.

@l
(eval-when (:compile-toplevel :load-toplevel :execute)
  #+(or foo bar baz)
  (frob this
        that
        and-another))

@*Index tests.

@ @l
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun count-em (list) (length list)))
(define-symbol-macro three-bears '(:fred :jerry :samuel))
(defmacro how-many-bears () `(count-em three-bears))

(defgeneric generic-foo (foo))

(defclass bear () ())
(defmacro define-bear-class (bear) `(defclass ,bear (bear) ()))

@ @l
(defun too-many-bears-p (n) (> n (how-many-bears)))

(defun compute-foo-generically (foo) (generic-foo foo))

(define-bear-class grizzly)

@ @l
(macrolet ((gently-frob (x) `(1+ ,x)))
  @<A lightly frobbed prime number@>)

@ @<A lightly...@>=
(gently-frob 27)

@*Index.
