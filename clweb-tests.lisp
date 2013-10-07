;;;; TANGLED WEB FROM "clweb.clw". DO NOT EDIT.
#+ALLEGRO
(EVAL-WHEN (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL)
  (SETQ EXCL:*SOURCE-PATHNAME* "clweb.clw"))

(IN-PACKAGE "CLWEB")
(EVAL-WHEN (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)
  (REQUIRE "RT")
  (DO-EXTERNAL-SYMBOLS (SYMBOL (FIND-PACKAGE "RT")) (IMPORT SYMBOL)))
(DEFTEST MAYBE-PUSH
         (LET ((LIST 'NIL))
           (MAYBE-PUSH 'A LIST)
           (MAYBE-PUSH NIL LIST)
           (MAYBE-PUSH 'B LIST)
           (MAYBE-PUSH "" LIST)
           (MAYBE-PUSH "foo" LIST)
           (NREVERSE LIST))
         (A B "foo"))
(EVAL-WHEN (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)
  (SETF (LOGICAL-PATHNAME-TRANSLATIONS "clweb-test") '(("**;*.*.*" ""))))
(EVAL-WHEN (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)
  (DEFUN PHYSICAL-PATHNAME-OR-NULL (PATHSPEC)
    (AND PATHSPEC (TRANSLATE-LOGICAL-PATHNAME PATHSPEC))))
(DEFMACRO DEFINE-PATHNAME-TEST (NAME FORM &REST EXPECTED-VALUES)
  (WITH-UNIQUE-NAMES (VALUES)
    `(DEFTEST ,NAME
              (LET* ((*DEFAULT-PATHNAME-DEFAULTS* #P"clweb-test:")
                     (,VALUES (MULTIPLE-VALUE-LIST ,FORM)))
                (VALUES-LIST (MAPCAR #'PHYSICAL-PATHNAME-OR-NULL ,VALUES)))
              ,@(MAPCAR #'PHYSICAL-PATHNAME-OR-NULL EXPECTED-VALUES))))
(DEFINE-PATHNAME-TEST OUTPUT-FILE-PATHNAME
 (VALUES (IGNORE-ERRORS (OUTPUT-FILE-PATHNAME #P"clweb-test:foo"))
         (OUTPUT-FILE-PATHNAME #P"clweb-test:foo" :DEFAULTS
                               *LISP-PATHNAME-DEFAULTS*)
         (OUTPUT-FILE-PATHNAME #P"clweb-test:foo" :OUTPUT-FILE
                               #P"clweb-test:bar" :DEFAULTS
                               *LISP-PATHNAME-DEFAULTS*)
         (OUTPUT-FILE-PATHNAME #P"clweb-test:foo" :OUTPUT-FILE
                               #P"clweb-test:bar.baz" :DEFAULTS
                               *LISP-PATHNAME-DEFAULTS*))
 NIL #P"clweb-test:foo.lisp.newest" #P"clweb-test:bar.lisp.newest"
 #P"clweb-test:bar.baz.newest")
(DEFINE-PATHNAME-TEST INPUT-FILE-PATHNAME
 (INPUT-FILE-PATHNAME #P"clweb-test:foo") #P"clweb-test:foo.clw.newest")
(DEFINE-PATHNAME-TEST LISP-FILE-PATHNAME
 (LISP-FILE-PATHNAME #P"clweb-test:foo") #P"clweb-test:foo.lisp.newest")
(DEFINE-PATHNAME-TEST TEX-FILE-PATHNAME (TEX-FILE-PATHNAME #P"clweb-test:foo")
 #P"clweb-test:foo.tex.newest")
(DEFINE-PATHNAME-TEST INDEX-FILE-PATHNAME
 (INDEX-FILE-PATHNAME #P"clweb-test:foo") #P"clweb-test:foo.idx.newest")
(DEFINE-PATHNAME-TEST SECTIONS-FILE-PATHNAME
 (SECTIONS-FILE-PATHNAME #P"clweb-test:foo") #P"clweb-test:foo.scn.newest")
(DEFINE-PATHNAME-TEST FASL-FILE-PATHNAME
 (FASL-FILE-PATHNAME #P"clweb-test:foo")
 #.(COMPILE-FILE-PATHNAME #P"clweb-test:foo.lisp.newest"))
(DEFINE-PATHNAME-TEST (TESTS-FILE-PATHNAME 1)
 (TESTS-FILE-PATHNAME #P"clweb-test:foo.clw" :OUTPUT-FILE
                      #P"clweb-test:foo.lisp" :TESTS-FILE #P"clweb-test:bar")
 #P"clweb-test:bar.lisp.newest")
(DEFINE-PATHNAME-TEST (TESTS-FILE-PATHNAME 2)
 (TESTS-FILE-PATHNAME #P"clweb-test:foo.clw" :OUTPUT-FILE #P"clweb-test:foo"
                      :TESTS-FILE NIL)
 NIL)
(DEFINE-PATHNAME-TEST (TESTS-FILE-PATHNAME 3)
 (TESTS-FILE-PATHNAME #P"clweb-test:foo.clw" :OUTPUT-FILE
                      #P"clweb-test:a;b;bar.tex")
 #P"clweb-test:a;b;bar-tests.tex.newest")
(DEFINE-PATHNAME-TEST (TANGLE-FILE-PATHNAMES 1)
 (TANGLE-FILE-PATHNAMES #P"clweb-test:foo")
 #.(COMPILE-FILE-PATHNAME #P"clweb-test:foo.lisp.newest")
 #P"clweb-test:foo.lisp.newest"
 #.(COMPILE-FILE-PATHNAME #P"clweb-test:foo-tests.lisp.newest")
 #P"clweb-test:foo-tests.lisp.newest")
(DEFINE-PATHNAME-TEST (TANGLE-FILE-PATHNAMES 2)
 (LET* ((INPUT-FILE #P"clweb-test:foo")
        (FASL-TYPE (PATHNAME-TYPE (COMPILE-FILE-PATHNAME INPUT-FILE)))
        (OUTPUT-FILE
         (MAKE-PATHNAME :TYPE FASL-TYPE :DEFAULTS #P"clweb-test:a;b;bar")))
   (TANGLE-FILE-PATHNAMES INPUT-FILE :OUTPUT-FILE OUTPUT-FILE))
 #.(COMPILE-FILE-PATHNAME #P"clweb-test:a;b;bar.lisp.newest")
 #P"clweb-test:a;b;bar.lisp.newest"
 #.(COMPILE-FILE-PATHNAME #P"clweb-test:a;b;bar-tests.lisp.newest")
 #P"clweb-test:a;b;bar-tests.lisp.newest")
(DEFINE-PATHNAME-TEST (TANGLE-FILE-PATHNAMES 3)
 (TANGLE-FILE-PATHNAMES #P"clweb-test:foo" :TESTS-FILE NIL)
 #.(COMPILE-FILE-PATHNAME #P"clweb-test:foo.lisp.newest")
 #P"clweb-test:foo.lisp.newest" NIL NIL)
(DEFINE-PATHNAME-TEST (WEAVE-PATHNAMES FOO)
 (WEAVE-PATHNAMES #P"clweb-test:foo") #P"clweb-test:foo.tex.newest"
 #P"clweb-test:foo.idx.newest" #P"clweb-test:foo.scn.newest")
(DEFINE-PATHNAME-TEST (WEAVE-PATHNAMES FOO.BAR)
 (WEAVE-PATHNAMES #P"clweb-test:foo.bar") #P"clweb-test:foo.tex.newest"
 #P"clweb-test:foo.idx.newest" #P"clweb-test:foo.scn.newest")
(DEFINE-PATHNAME-TEST (WEAVE-PATHNAMES FOO :OUTPUT-FILE T)
 (WEAVE-PATHNAMES #P"clweb-test:foo" :OUTPUT-FILE
                  #P"clweb-test:a;bar.baz.newest")
 #P"clweb-test:a;bar.baz.newest" #P"clweb-test:a;bar.idx.newest"
 #P"clweb-test:a;bar.scn.newest")
(DEFINE-PATHNAME-TEST (WEAVE-PATHNAMES FOO :OUTPUT-FILE BAR)
 (WEAVE-PATHNAMES #P"clweb-test:foo" :OUTPUT-FILE #P"clweb-test:bar")
 #P"clweb-test:bar.tex.newest" #P"clweb-test:bar.idx.newest"
 #P"clweb-test:bar.scn.newest")
(DEFTEST (WEAVE-PATHNAMES FOO :OUTPUT-FILE BAR.T)
         (PATHNAME-TYPE
          (WEAVE-PATHNAMES #P"clweb-test:foo" :OUTPUT-FILE
                           #P"clweb-test:bar.t")
          :CASE :COMMON)
         "T")
#-:ALLEGRO
(deftest (weave-pathnames foo :output-file (:type :unspecific))
  (pathname-type
   (weave-pathnames #P"clweb-test:foo" ;
                    :output-file (make-pathname :host "clweb-test" ;
                                                :type :unspecific)))
  :unspecific)
(DEFINE-PATHNAME-TEST (WEAVE-PATHNAMES FOO :INDEX-FILE NIL)
 (WEAVE-PATHNAMES #P"clweb-test:foo" :INDEX-FILE NIL)
 #P"clweb-test:foo.tex.newest" NIL NIL)
(DEFINE-PATHNAME-TEST (WEAVE-PATHNAMES FOO :INDEX-FILE BAR)
 (WEAVE-PATHNAMES #P"clweb-test:foo" :INDEX-FILE #P"clweb-test:bar")
 #P"clweb-test:foo.tex.newest" #P"clweb-test:bar.idx.newest"
 #P"clweb-test:bar.scn.newest")
(DEFINE-PATHNAME-TEST (WEAVE-PATHNAMES FOO :OUTPUT-FILE T :INDEX-FILE T)
 (WEAVE-PATHNAMES #P"clweb-test:foo" :OUTPUT-FILE
                  #P"clweb-test:a;bar.tex.newest" :INDEX-FILE
                  #P"clweb-test:b;index.idx.newest")
 #P"clweb-test:a;bar.tex.newest" #P"clweb-test:b;index.idx.newest"
 #P"clweb-test:b;index.scn.newest")
(DEFMETHOD SECTION-NUMBER ((SECTION INTEGER)) SECTION)
(DEFTEST CURRENT-SECTION
         (LET ((*SECTIONS* (MAKE-ARRAY 1 :FILL-POINTER 0)))
           (EQL (MAKE-INSTANCE 'SECTION) *CURRENT-SECTION*))
         T)
(DEFMACRO WITH-TEMPORARY-SECTIONS (SECTIONS &BODY BODY)
  (WITH-UNIQUE-NAMES (SPEC SECTION NAME)
    `(LET ((*SECTIONS* (MAKE-ARRAY 16 :ADJUSTABLE T :FILL-POINTER 0))
           (*TEST-SECTIONS* (MAKE-ARRAY 16 :ADJUSTABLE T :FILL-POINTER 0))
           (*NAMED-SECTIONS* NIL))
       (DOLIST (,SPEC ,SECTIONS)
         (LET* ((,SECTION
                 (APPLY #'MAKE-INSTANCE
                        (ECASE (POP ,SPEC)
                          (:SECTION 'SECTION)
                          (:STARRED-SECTION 'STARRED-SECTION)
                          (:LIMBO 'LIMBO-SECTION))
                        ,SPEC))
                (,NAME (SECTION-NAME ,SECTION)))
           (WHEN ,NAME
             (PUSH ,SECTION (NAMED-SECTION-SECTIONS (FIND-SECTION ,NAME))))))
       ,@BODY)))
(DEFTEST (BST SIMPLE)
         (LET ((TREE (MAKE-INSTANCE 'BINARY-SEARCH-TREE :KEY 0)))
           (FIND-OR-INSERT -1 TREE)
           (FIND-OR-INSERT 1 TREE)
           (VALUES (NODE-KEY TREE) (NODE-KEY (LEFT-CHILD TREE))
                   (NODE-KEY (RIGHT-CHILD TREE))))
         0 -1 1)
(DEFTEST (BST RANDOM)
         (LET ((TREE (MAKE-INSTANCE 'BINARY-SEARCH-TREE :KEY 0))
               (NUMBERS
                (CONS 0
                      (LOOP WITH LIMIT = 1000
                            FOR I FROM 1 TO LIMIT
                            COLLECT (RANDOM LIMIT)))))
           (DOLIST (N NUMBERS) (FIND-OR-INSERT N TREE))
           (LET ((KEYS 'NIL))
             (FLET ((PUSH-KEY (NODE)
                      (PUSH (NODE-KEY NODE) KEYS)))
               (MAP-BST #'PUSH-KEY TREE)
               (EQUAL (NREVERSE KEYS)
                      (REMOVE-DUPLICATES (SORT NUMBERS #'<))))))
         T)
(DEFTEST (BST FIND-NO-INSERT)
         (LET ((TREE (MAKE-INSTANCE 'BINARY-SEARCH-TREE :KEY 0)))
           (FIND-OR-INSERT -1 TREE :INSERT-IF-NOT-FOUND NIL))
         NIL NIL)
(DEFTEST NAMED-SECTION-NUMBER/CODE
         (WITH-TEMPORARY-SECTIONS
          '((:SECTION :NAME "foo" :CODE (1)) (:SECTION :NAME "foo" :CODE (2))
            (:SECTION :NAME "foo" :CODE (3)))
          (LET ((SECTION (FIND-SECTION "foo")))
            (VALUES (SECTION-CODE SECTION) (SECTION-NUMBER SECTION))))
         (1 2 3) 0)
(DEFTEST UNDEFINED-NAMED-SECTION
         (HANDLER-CASE
          (SECTION-NUMBER (MAKE-INSTANCE 'NAMED-SECTION :NAME "foo"))
          (UNDEFINED-NAMED-SECTION-ERROR NIL :ERROR))
         :ERROR)
(DEFTEST (SECTION-NAME-PREFIX-P 1) (SECTION-NAME-PREFIX-P "a") NIL 1)
(DEFTEST (SECTION-NAME-PREFIX-P 2) (SECTION-NAME-PREFIX-P "ab...") T 2)
(DEFTEST (SECTION-NAME-PREFIX-P 3) (SECTION-NAME-PREFIX-P "abcd...") T 4)
(DEFTEST (SECTION-NAME-LESSP 1) (SECTION-NAME-LESSP "b" "a") NIL)
(DEFTEST (SECTION-NAME-LESSP 2) (SECTION-NAME-LESSP "b..." "a...") NIL)
(DEFTEST (SECTION-NAME-LESSP 3) (SECTION-NAME-LESSP "ab" "a...") NIL)
(DEFTEST (SECTION-NAME-EQUAL 1) (SECTION-NAME-EQUAL "a" "b") NIL)
(DEFTEST (SECTION-NAME-EQUAL 2) (SECTION-NAME-EQUAL "a" "a") T)
(DEFTEST (SECTION-NAME-EQUAL 3) (SECTION-NAME-EQUAL "a..." "ab") T)
(DEFTEST (SECTION-NAME-EQUAL 4) (SECTION-NAME-EQUAL "a..." "ab...") T)
(DEFTEST (SQUEEZE 1) (SQUEEZE "abc") "abc")
(DEFTEST (SQUEEZE 2) (SQUEEZE "ab c") "ab c")
(DEFTEST (SQUEEZE 3) (SQUEEZE (FORMAT NIL " a b ~C c " #\Tab)) "a b c")
(DEFVAR *SAMPLE-NAMED-SECTIONS*
  (WITH-TEMPORARY-SECTIONS
   '((:SECTION :NAME "foo" :CODE (:FOO)) (:SECTION :NAME "bar" :CODE (:BAR))
     (:SECTION :NAME "baz" :CODE (:BAZ))
     (:SECTION :NAME "quux" :CODE (:QUUX :QUUUX :QUUUUX)))
   *NAMED-SECTIONS*))
(DEFMACRO WITH-SAMPLE-NAMED-SECTIONS (&BODY BODY)
  `(LET ((*NAMED-SECTIONS* *SAMPLE-NAMED-SECTIONS*))
     ,@BODY))
(DEFUN FIND-SAMPLE-SECTION (NAME)
  (FIND-OR-INSERT NAME *SAMPLE-NAMED-SECTIONS* :INSERT-IF-NOT-FOUND NIL))
(DEFTEST FIND-NAMED-SECTION (SECTION-NAME (FIND-SAMPLE-SECTION "foo")) "foo")
(DEFTEST FIND-SECTION-BY-PREFIX (SECTION-NAME (FIND-SAMPLE-SECTION "f..."))
         "foo")
(DEFTEST FIND-SECTION-BY-AMBIGUOUS-PREFIX
         (LET ((HANDLED NIL))
           (VALUES
            (SECTION-NAME
             (HANDLER-BIND ((AMBIGUOUS-PREFIX-ERROR
                             (LAMBDA (CONDITION)
                               (DECLARE (IGNORE CONDITION))
                               (SETQ HANDLED T)
                               (INVOKE-RESTART 'USE-FIRST-MATCH))))
               (FIND-SAMPLE-SECTION "b...")))
            HANDLED))
         "bar" T)
(DEFTEST FIND-SECTION
         (WITH-SAMPLE-NAMED-SECTIONS
          (FIND-SECTION (FORMAT NIL " foo  bar ~C baz..." #\Tab))
          (SECTION-NAME (FIND-SECTION "foo...")))
         "foo")
(DEFTEST (READTABLE-FOR-MODE 1) (READTABLEP (READTABLE-FOR-MODE :TEX)) T)
(DEFTEST (READTABLE-FOR-MODE 2) (READTABLEP (READTABLE-FOR-MODE NIL)) T)
(DEFTEST (READTABLE-FOR-MODE 3)
         (EQL (READTABLE-FOR-MODE :TEX) (READTABLE-FOR-MODE :LISP)) NIL)
(DEFTEST WITH-MODE
         (LOOP FOR (MODE . READTABLE) IN *READTABLES*
               ALWAYS (WITH-MODE MODE
                        (EQL *READTABLE* READTABLE)))
         T)
(DEFTEST EOF-P (EOF-P (READ-FROM-STRING "" NIL EOF)) T)
(DEFTEST EOF-TYPE (TYPEP (READ-FROM-STRING "" NIL EOF) 'EOF) T)
(DEFTEST (TOKEN-DELIMITER-P 1) (NOT (TOKEN-DELIMITER-P #\ )) NIL)
(DEFTEST (TOKEN-DELIMITER-P 2) (NOT (TOKEN-DELIMITER-P #\))) NIL)
(DEFTEST (READ-MAYBE-NOTHING 1)
         (WITH-INPUT-FROM-STRING (S "123") (READ-MAYBE-NOTHING S)) (123))
(DEFTEST (READ-MAYBE-NOTHING 2)
         (LET ((*READTABLE* (COPY-READTABLE NIL)))
           (SET-MACRO-CHARACTER #\!
                                (WRAP-READER-MACRO-FUNCTION
                                 (LAMBDA (STREAM CHAR)
                                   (DECLARE (IGNORE STREAM CHAR))
                                   (VALUES))))
           (WITH-INPUT-FROM-STRING (S "!") (READ-MAYBE-NOTHING S)))
         NIL)
(DEFTEST READ-MAYBE-NOTHING-PRESERVING-WHITESPACE
         (WITH-INPUT-FROM-STRING (S "x y")
           (READ-MAYBE-NOTHING-PRESERVING-WHITESPACE S T NIL NIL)
           (PEEK-CHAR NIL S))
         #\ )
(DEFTEST CHARPOS-INPUT-STREAM
         (LET ((*TAB-WIDTH* 8))
           (WITH-CHARPOS-INPUT-STREAM (S
                                       (MAKE-STRING-INPUT-STREAM
                                        (FORMAT NIL "012~%abc~C~C" #\Tab
                                                #\Tab)))
             (VALUES (STREAM-CHARPOS S) (READ-LINE S) (STREAM-CHARPOS S)
                     (READ-CHAR S) (READ-CHAR S) (READ-CHAR S)
                     (STREAM-CHARPOS S) (READ-CHAR S) (STREAM-CHARPOS S)
                     (READ-CHAR S) (STREAM-CHARPOS S))))
         0 "012" 0 #\a #\b #\c 3 #\Tab 8 #\Tab 16)
(DEFTEST CHARPOS-OUTPUT-STREAM
         (LET ((STRING-STREAM (MAKE-STRING-OUTPUT-STREAM)))
           (WITH-CHARPOS-OUTPUT-STREAM (S STRING-STREAM)
             (VALUES (STREAM-CHARPOS S)
                     (PROGN (WRITE-STRING "012" S) (STREAM-CHARPOS S))
                     (PROGN (WRITE-CHAR #\Newline S) (STREAM-CHARPOS S))
                     (PROGN (WRITE-STRING "abc" S) (STREAM-CHARPOS S))
                     (GET-OUTPUT-STREAM-STRING STRING-STREAM))))
         0 3 0 3 #.(FORMAT NIL "012~%abc"))
(DEFTEST REWIND-STREAM
         (WITH-INPUT-FROM-STRING (S "abcdef")
           (WITH-REWIND-STREAM (R S)
             (VALUES (READ-CHAR R) (READ-CHAR R) (READ-CHAR R)
                     (PROGN (REWIND) (READ-CHAR R))
                     (PROGN (REWIND) (READ-LINE R)))))
         #\a #\b #\c #\a "bcdef")
(DEFTEST (READ-WITH-ECHO EOF)
         (WITH-INPUT-FROM-STRING (STREAM ":foo")
           (READ-WITH-ECHO (STREAM OBJECT CHARS)
             (VALUES OBJECT CHARS)))
         :FOO ":foo")
(DEFTEST (READ-WITH-ECHO SPACE)
         (WITH-INPUT-FROM-STRING (STREAM ":foo :bar")
           (READ-WITH-ECHO (STREAM OBJECT CHARS)
             (VALUES OBJECT CHARS)))
         :FOO ":foo")
(DEFTEST (READ-WITH-ECHO STRING)
         (WITH-INPUT-FROM-STRING (STREAM "\"foo\" :bar")
           (READ-WITH-ECHO (STREAM OBJECT CHARS)
             (VALUES OBJECT CHARS)))
         "foo" "\"foo\"")
(DEFTEST (READ-WITH-ECHO PAREN)
         (WITH-INPUT-FROM-STRING (STREAM ":foo)")
           (READ-WITH-ECHO (STREAM OBJECT CHARS)
             (VALUES OBJECT CHARS)))
         :FOO ":foo")
(DEFTEST (READ-WITH-ECHO VECTOR)
         (WITH-INPUT-FROM-STRING (STREAM "#(1 2 3) :foo")
           (READ-WITH-ECHO (STREAM OBJECT CHARS)
             (VALUES OBJECT CHARS)))
         #(1 2 3) "#(1 2 3)")
(DEFTEST PRINT-MARKER
         (WRITE-TO-STRING (MAKE-INSTANCE 'MARKER :VALUE :FOO) :PPRINT-DISPATCH
                          *TANGLE-PPRINT-DISPATCH* :PRETTY T)
         ":FOO")
(DEFMETHOD PRINT-OBJECT ((OBJ MARKER) STREAM)
  (PRINT-UNREADABLE-OBJECT (OBJ STREAM :TYPE T :IDENTITY T)
    (WHEN (MARKER-BOUNDP OBJ) (PRINC (MARKER-VALUE OBJ) STREAM))))
(DEFTEST PRINT-MARKER-UNREADABLY
         (LET ((*PRINT-READABLY* T))
           (HANDLER-CASE (FORMAT NIL "~W" (MAKE-INSTANCE 'MARKER :VALUE :FOO))
                         (PRINT-NOT-READABLE (CONDITION)
                          (MARKER-VALUE
                           (PRINT-NOT-READABLE-OBJECT CONDITION)))))
         :FOO)
(DEFTEST READ-NEWLINE
         (NEWLINEP
          (WITH-INPUT-FROM-STRING (S (FORMAT NIL "~%"))
            (WITH-MODE :LISP
              (READ S))))
         T)
(DEFTEST READ-PAR
         (TYPEP
          (WITH-INPUT-FROM-STRING (S (FORMAT NIL "~%~%"))
            (WITH-MODE :LISP
              (READ S)))
          'PAR-MARKER)
         T)
(DEFMACRO READ-FROM-STRING-WITH-CHARPOS
          (STRING &OPTIONAL (EOF-ERROR-P T) (EOF-VALUE NIL))
  (WITH-UNIQUE-NAMES (STRING-STREAM CHARPOS-STREAM)
    `(WITH-OPEN-STREAM (,STRING-STREAM (MAKE-STRING-INPUT-STREAM ,STRING))
       (WITH-CHARPOS-INPUT-STREAM (,CHARPOS-STREAM ,STRING-STREAM)
         (READ ,CHARPOS-STREAM ,EOF-ERROR-P ,EOF-VALUE)))))
(DEFUN READ-FORM-FROM-STRING (STRING &KEY (MODE :LISP))
  (LET ((*PACKAGE* (FIND-PACKAGE "CLWEB")))
    (WITH-MODE MODE
      (READ-FROM-STRING-WITH-CHARPOS STRING))))
(DEFTEST (READ-EMPTY-LIST :INNER-LISP)
         (TYPEP (READ-FORM-FROM-STRING "()" :MODE :INNER-LISP)
                'EMPTY-LIST-MARKER)
         T)
(DEFTEST (READ-LIST :INNER-LISP)
         (LISTP (READ-FORM-FROM-STRING "(:a :b :c)" :MODE :INNER-LISP)) T)
(DEFTEST READ-EMPTY-LIST
         (TYPEP (READ-FORM-FROM-STRING "()") 'EMPTY-LIST-MARKER) T)
(DEFMACRO DEFINE-LIST-READER-TEST (NAME STRING EXPECTED-LIST EXPECTED-CHARPOS)
  `(DEFTEST ,NAME
            (LET* ((MARKER (READ-FORM-FROM-STRING ,STRING))
                   (LIST (MARKER-VALUE MARKER))
                   (CHARPOS (LIST-MARKER-CHARPOS MARKER)))
              (AND (EQUAL LIST ',EXPECTED-LIST)
                   (EQUAL CHARPOS ',EXPECTED-CHARPOS)))
            T))
(DEFINE-LIST-READER-TEST (LIST-READER 1) "(a b c)" (A B C) (1 3 5))
(DEFINE-LIST-READER-TEST (LIST-READER 2) "(a b . c)" (A B . C) (1 3 5 7))
(DEFINE-LIST-READER-TEST (LIST-READER 3) "(a b .c)" (A B .C) (1 3 5))
(DEFINE-LIST-READER-TEST (LIST-READER 4) "(a b #|c|#)" (A B) (1 3))
(DEFINE-LIST-READER-TEST (LIST-READER 5) "(#|foo|#)" NIL NIL)
(DEFTEST READ-LIST-ERROR
         (HANDLER-CASE (READ-FORM-FROM-STRING "(. a)")
                       (READER-ERROR NIL :ERROR))
         :ERROR)
(DEFTEST READ-DOTTED-LIST
         (WITH-INPUT-FROM-STRING (STREAM "(foo .(foo))")
           (WITH-CHARPOS-INPUT-STREAM (CSTREAM STREAM)
             (WITH-MODE :LISP
               (READ CSTREAM)
               (PEEK-CHAR NIL CSTREAM NIL))))
         NIL)
(DEFTEST READ-QUOTED-FORM
         (LET ((MARKER (READ-FORM-FROM-STRING "':foo")))
           (VALUES (QUOTED-FORM MARKER) (MARKER-VALUE MARKER)))
         :FOO ':FOO)
(DEFTEST READ-COMMENT
         (LET ((MARKER (READ-FORM-FROM-STRING "; foo")))
           (VALUES (COMMENT-TEXT MARKER) (MARKER-BOUNDP MARKER)))
         "; foo" NIL)
(DEFTEST READ-EMPTY-COMMENT
         (WITH-INPUT-FROM-STRING (S (FORMAT NIL ";~%"))
           (WITH-MODE :LISP
             (READ-MAYBE-NOTHING S)))
         NIL)
(DEFMETHOD PRINT-OBJECT ((OBJECT COMMA) STREAM)
  (PRINT-UNREADABLE-OBJECT (OBJECT STREAM)
    (FORMAT STREAM ",~@[~C~]~S" (COMMA-MODIFIER OBJECT) (COMMA-FORM OBJECT))))
(DEFTEST (BQ 1)
         (LET ((B 3))
           (DECLARE (SPECIAL B))
           (EQUAL
            (EVAL (TANGLE (READ-FORM-FROM-STRING "`(a b ,b ,(+ b 1) b)")))
            '(A B 3 4 B)))
         T)
(DEFTEST (BQ 2)
         (LET ((X '(A B C)))
           (DECLARE (SPECIAL X))
           (EQUAL
            (EVAL
             (TANGLE
              (READ-FORM-FROM-STRING
               "`(x ,x ,@x foo ,(cadr x) bar ,(cdr x) baz ,@(cdr x))")))
            '(X (A B C) A B C FOO B BAR (B C) BAZ B C)))
         T)
(DEFUN R (X) (REDUCE #'* X))
(DEFTEST (BQ NESTED)
         (LET ((Q '(R S)) (R '(3 5)) (S '(4 6)))
           (DECLARE (SPECIAL Q R S))
           (VALUES (EVAL (EVAL (TANGLE (READ-FORM-FROM-STRING "``(,,q)"))))
                   (EVAL (EVAL (TANGLE (READ-FORM-FROM-STRING "``(,@,q)"))))
                   (EVAL (EVAL (TANGLE (READ-FORM-FROM-STRING "``(,,@q)"))))
                   (EVAL (EVAL (TANGLE (READ-FORM-FROM-STRING "``(,@,@q)"))))))
         (24) 24 ((3 5) (4 6)) (3 5 4 6))
(DEFTEST (BQ VECTOR)
         (LET ((A '(1 2 3)))
           (DECLARE (SPECIAL A))
           (VALUES (EVAL (TANGLE (READ-FORM-FROM-STRING "`#(:a)")))
                   (EVAL (TANGLE (READ-FORM-FROM-STRING "`#(\"a\")")))
                   (EVAL (TANGLE (READ-FORM-FROM-STRING "`#(,a)")))
                   (EVAL (TANGLE (READ-FORM-FROM-STRING "`#(,@a)")))))
         #(:A) #("a") #((1 2 3)) #(1 2 3))
(DEFTEST (BQ NAMED-SECTION)
         (WITH-SAMPLE-NAMED-SECTIONS
          (VALUES (EVAL (TANGLE (READ-FORM-FROM-STRING "`(, @<foo@>)")))
                  (EVAL (TANGLE (READ-FORM-FROM-STRING "`(,@ @<foo@>)")))))
         (:FOO) :FOO)
(DEFTEST (BQ TOO-MANY-FORMS)
         (WITH-SAMPLE-NAMED-SECTIONS
          (LET ((HANDLED NIL))
            (HANDLER-BIND ((ERROR
                            (LAMBDA (CONDITION)
                              (SETQ HANDLED T)
                              (CONTINUE CONDITION))))
              (VALUES (EVAL (TANGLE (READ-FORM-FROM-STRING "`(,@ @<quux@>)")))
                      HANDLED))))
         :QUUX T)
(DEFTEST READ-FUNCTION
         (LET ((MARKER (READ-FORM-FROM-STRING "#'identity")))
           (VALUES (QUOTED-FORM MARKER) (MARKER-VALUE MARKER)))
         IDENTITY #'IDENTITY)
(DEFTEST READ-SIMPLE-VECTOR
         (VALUES (MARKER-VALUE (READ-FORM-FROM-STRING "#5(:a :b :c #C(0 1))"))
                 (MARKER-VALUE (READ-FORM-FROM-STRING "#0()")))
         #(:A :B :C #C(0 1) #C(0 1)) #())
(DEFTEST READ-BIT-VECTOR (MARKER-VALUE (READ-FORM-FROM-STRING "#6*101"))
         #*101111)
(DEFTEST (READ-TIME-EVAL 1)
         (LET* ((*READ-EVAL* T) (*EVALUATING* NIL))
           (WRITE-TO-STRING (MARKER-VALUE (READ-FORM-FROM-STRING "#.(+ 1 1)"))
                            :PPRINT-DISPATCH *TANGLE-PPRINT-DISPATCH* :PRETTY
                            T))
         "#.(+ 1 1)")
(DEFTEST (READ-TIME-EVAL 2)
         (LET* ((*READ-EVAL* T) (*EVALUATING* T))
           (MARKER-VALUE (READ-FORM-FROM-STRING "#.(+ 1 1)")))
         2)
(DEFTEST (READ-RADIX 1)
         (LET ((MARKER (READ-FORM-FROM-STRING "#B1011")))
           (VALUES (RADIX-MARKER-BASE MARKER) (MARKER-VALUE MARKER)))
         2 11)
(DEFTEST (READ-RADIX 2)
         (LET ((MARKER (READ-FORM-FROM-STRING "#14R11")))
           (VALUES (RADIX-MARKER-BASE MARKER) (MARKER-VALUE MARKER)))
         14 15)
(DEFTEST READ-COMPLEX
         (LET ((MARKER (READ-FORM-FROM-STRING "#C(0 1)")))
           (MARKER-VALUE MARKER))
         #C(0 1))
(DEFTEST READ-ARRAY
         (VALUES (MARKER-VALUE (READ-FORM-FROM-STRING "#2A((1 2 3) (4 5 6))"))
                 (MARKER-VALUE (READ-FORM-FROM-STRING "#2A()")))
         #2A((1 2 3) (4 5 6)) #2A())
(DEFSTRUCT PERSON (NAME 7 :TYPE STRING))
(DEFTEST STRUCTURE-MARKER
         (PERSON-NAME
          (MARKER-VALUE (READ-FORM-FROM-STRING "#S(person :name \"James\")")))
         "James")
(DEFTEST FEATUREP
         (LET ((*FEATURES* '(:A :B)))
           (FEATUREP '(:AND :A (:OR :C :B) (:NOT :D))))
         T)
(DEFTEST (READ-TIME-CONDITIONAL 1)
         (LET* ((*EVALUATING* NIL)
                (*FEATURES* NIL)
                (CONDITIONAL (MARKER-VALUE (READ-FORM-FROM-STRING "#-foo 1"))))
           (VALUES (READ-TIME-CONDITIONAL-PLUSP CONDITIONAL)
                   (READ-TIME-CONDITIONAL-TEST CONDITIONAL)
                   (READ-TIME-CONDITIONAL-FORM CONDITIONAL)))
         NIL :FOO " 1")
(DEFTEST (READ-TIME-CONDITIONAL 2)
         (LET ((*FEATURES* '(:A)) (*EVALUATING* T))
           (VALUES (MARKER-VALUE (READ-FORM-FROM-STRING "#+a 1"))
                   (MARKER-VALUE (READ-FORM-FROM-STRING "#-b 2"))
                   (MARKER-BOUNDP (READ-FORM-FROM-STRING "#-a 1"))
                   (MARKER-BOUNDP (READ-FORM-FROM-STRING "#+b 2"))))
         1 2 NIL NIL)
(DEFTEST (READ-TIME-CONDITIONAL CHARPOS)
         (LIST-MARKER-CHARPOS
          (WITH-MODE :LISP
            (READ-FROM-STRING-WITH-CHARPOS (FORMAT NIL "(#-:foo foo~% bar)"))))
         (1 0 1))
(DEFTEST READ-BLOCK-COMMENT
         (WITH-INPUT-FROM-STRING (S "#|foo|#")
           (WITH-MODE :LISP
             (READ-MAYBE-NOTHING S)))
         NIL)
(DEFTEST SNARF-UNTIL-CONTROL-CHAR
         (WITH-INPUT-FROM-STRING (S "abc*123")
           (VALUES (SNARF-UNTIL-CONTROL-CHAR S #\*)
                   (SNARF-UNTIL-CONTROL-CHAR S '(#\a #\3))))
         "abc" "*12")
(DEFTEST READ-INNER-LISP
         (WITH-MODE :TEX
           (VALUES (READ-FROM-STRING "|:foo :bar|")))
         (:FOO :BAR))
(DEFTEST LITERAL-@
         (WITH-MODE :TEX
           (VALUES (READ-FROM-STRING "@@")))
         "@")
(DEFTEST @Q-LISP
         (WITH-MODE :LISP
           (VALUES (READ-FROM-STRING (FORMAT NIL "@q nil~%t"))))
         T)
(DEFTEST START-TEST-SECTION-READER
         (LET ((*TEST-SECTIONS* (MAKE-ARRAY 2 :FILL-POINTER 0)))
           (WITH-INPUT-FROM-STRING (S (FORMAT NIL "@t~%:foo @t* :bar"))
             (WITH-MODE :LISP
               (VALUES (TYPEP (READ S) 'TEST-SECTION) (READ S)
                       (TYPEP (READ S) 'STARRED-TEST-SECTION) (READ S)))))
         T :FOO T :BAR)
(DEFTEST START-CODE-MARKER
         (WITH-MODE :TEX
           (VALUES-LIST
            (MAPCAR (LAMBDA (MARKER) (TYPEP MARKER 'START-CODE-MARKER))
                    (LIST (READ-FROM-STRING "@l") (READ-FROM-STRING "@p")))))
         T T)
(DEFTEST (READ-EVALUATED-FORM 1)
         (LET ((MARKER (READ-FORM-FROM-STRING (FORMAT NIL "@e t"))))
           (AND (TYPEP MARKER 'EVALUATED-FORM-MARKER) (MARKER-VALUE MARKER)))
         T)
(DEFTEST (READ-EVALUATED-FORM 2)
         (LET ((MARKER (READ-FORM-FROM-STRING (FORMAT NIL "@e~%t"))))
           (AND (TYPEP MARKER 'EVALUATED-FORM-MARKER) (MARKER-VALUE MARKER)))
         T)
(DEFTEST READ-CONTROL-TEXT
         (WITH-INPUT-FROM-STRING (S "frob |foo| and tweak |bar|@>")
           (READ-CONTROL-TEXT S))
         "frob |foo| and tweak |bar|")
(DEFTEST (READ-SECTION-NAME :TEX)
         (WITH-MODE :TEX
           (SECTION-NAME (READ-FROM-STRING "@<foo@>=")))
         "foo")
(DEFTEST (READ-SECTION-NAME :LISP)
         (WITH-SAMPLE-NAMED-SECTIONS
          (WITH-MODE :LISP
            (SECTION-NAME (READ-FROM-STRING "@<foo@>"))))
         "foo")
(DEFTEST SECTION-NAME-DEFINITION-ERROR
         (WITH-SAMPLE-NAMED-SECTIONS
          (SECTION-NAME
           (HANDLER-BIND ((SECTION-NAME-DEFINITION-ERROR
                           (LAMBDA (CONDITION)
                             (DECLARE (IGNORE CONDITION))
                             (INVOKE-RESTART 'USE-SECTION))))
             (WITH-MODE :LISP
               (READ-FROM-STRING "@<foo@>=")))))
         "foo")
(DEFTEST SECTION-NAME-USE-ERROR
         (WITH-SAMPLE-NAMED-SECTIONS
          (SECTION-NAME
           (HANDLER-BIND ((SECTION-NAME-USE-ERROR
                           (LAMBDA (CONDITION)
                             (DECLARE (IGNORE CONDITION))
                             (INVOKE-RESTART 'CITE-SECTION))))
             (WITH-MODE :TEX
               (READ-FROM-STRING "@<foo@>")))))
         "foo")
(DEFTEST INDEX-PACKAGE-READER
         (LET ((*INDEX-PACKAGES* NIL))
           (READ-FORM-FROM-STRING "@x\"CLWEB\"")
           (NOT (NULL (INTERESTING-SYMBOL-P 'INDEX-PACKAGE-READER))))
         T)
(DEFTEST (TANGLE-1 1) (TANGLE-1 (READ-FORM-FROM-STRING ":a")) :A NIL)
(DEFTEST (TANGLE-1 2) (TANGLE-1 (READ-FORM-FROM-STRING "(:a :b :c)"))
         (:A :B :C) T)
(DEFTEST (TANGLE-1 3)
         (WITH-SAMPLE-NAMED-SECTIONS
          (TANGLE-1 (READ-FORM-FROM-STRING "@<foo@>")))
         (:FOO) T)
(DEFTEST TANGLE
         (WITH-SAMPLE-NAMED-SECTIONS
          (TANGLE (READ-FORM-FROM-STRING (FORMAT NIL "(:a @<foo@>~% :b)"))))
         (:A :FOO :B) T)
(DEFTEST PRINT-ESCAPED
         (WITH-OUTPUT-TO-STRING (S) (PRINT-ESCAPED S "foo#{bar}*baz"))
         "foo\\#$\\{$bar$\\}$*baz")
(DEFMETHOD PRINT-OBJECT ((X NAMESPACE) STREAM)
  (PRINT-UNREADABLE-OBJECT (X STREAM :TYPE T :IDENTITY T)
    (WHEN (LOCAL-BINDING-P X) (PRIN1 :LOCAL STREAM))))
(DEFTEST (UPDATE-CONTEXT GENERIC-SETF)
         (TYPEP
          (UPDATE-CONTEXT '(SETF CLASS-NAME) (MAKE-CONTEXT 'OPERATOR) NIL)
          'GENERIC-SETF-FUNCTION-NAME)
         T)
(DEFTEST (UPDATE-CONTEXT MACRO)
         (LET ((CONTEXT (UPDATE-CONTEXT 'SETF (MAKE-CONTEXT 'OPERATOR) NIL)))
           (AND (TYPEP CONTEXT 'MACRO-NAME) (NOT (LOCAL-BINDING-P CONTEXT))))
         T)
(DEFTEST (UPDATE-CONTEXT LOCAL-MACRO)
         (LET ((CONTEXT
                (UPDATE-CONTEXT 'FOO (MAKE-CONTEXT 'OPERATOR)
                                (AUGMENT-ENVIRONMENT
                                 (ENSURE-PORTABLE-WALKING-ENVIRONMENT NIL)
                                 :MACRO
                                 `((FOO
                                    ,(LAMBDA (FORM ENV)
                                       (DECLARE (IGNORE ENV))
                                       FORM)))))))
           (AND (TYPEP CONTEXT 'MACRO-NAME) (LOCAL-BINDING-P CONTEXT)))
         T)
(DEFTEST (UPDATE-CONTEXT FUNCTION)
         (LET ((CONTEXT
                (UPDATE-CONTEXT 'IDENTITY (MAKE-CONTEXT 'OPERATOR) NIL)))
           (AND (TYPEP CONTEXT 'FUNCTION-NAME)
                (NOT (LOCAL-BINDING-P CONTEXT))))
         T)
(DEFTEST (UPDATE-CONTEXT LOCAL-FUNCTION)
         (LET ((CONTEXT
                (UPDATE-CONTEXT 'FOO (MAKE-CONTEXT 'OPERATOR)
                                (AUGMENT-ENVIRONMENT
                                 (ENSURE-PORTABLE-WALKING-ENVIRONMENT NIL)
                                 :FUNCTION '(FOO)))))
           (AND (TYPEP CONTEXT 'FUNCTION-NAME) (LOCAL-BINDING-P CONTEXT)))
         T)
(DEFTEST (UPDATE-CONTEXT SPECIAL-OPERATOR)
         (LET ((CONTEXT (UPDATE-CONTEXT 'IF (MAKE-CONTEXT 'OPERATOR) NIL)))
           (AND (TYPEP CONTEXT 'SPECIAL-OPERATOR)
                (NOT (LOCAL-BINDING-P CONTEXT))))
         T)
(DEFTEST WALK-ATOMIC-FORM
         (WALK-ATOMIC-FORM (MAKE-INSTANCE 'WALKER) ':FOO NIL NIL) :FOO)
(DEFTEST WALK-NON-ATOMIC-FORM
         (HANDLER-CASE
          (WALK-ATOMIC-FORM (MAKE-INSTANCE 'WALKER) '(A B C) NIL NIL)
          (ERROR NIL NIL))
         NIL)
(DEFTEST WALK-COMPOUND-FORM
         (WALK-COMPOUND-FORM (MAKE-INSTANCE 'WALKER) :FOO '(:FOO 2 3) NIL)
         (:FOO 2 3))
(DEFTEST (WALK-COMPOUND-FORM LAMBDA)
         (LET ((OPERATOR '(LAMBDA (X) X)))
           (WALK-COMPOUND-FORM (MAKE-INSTANCE 'WALKER) OPERATOR `(,OPERATOR 0)
                               (ENSURE-PORTABLE-WALKING-ENVIRONMENT NIL)))
         ((LAMBDA (X) X) 0))
(DEFTEST (WALK-COMPOUND-FORM INVALID)
         (HANDLER-CASE
          (LET ((OPERATOR '(X)))
            (WALK-COMPOUND-FORM (MAKE-INSTANCE 'WALKER) OPERATOR `(,OPERATOR 0)
                                (ENSURE-PORTABLE-WALKING-ENVIRONMENT NIL)))
          (ERROR NIL NIL))
         NIL)
(DEFTEST LAMBDA-EXPRESSION-TYPE
         (FLET ((LAMBDA-EXPRESSION-P (X)
                  (TYPEP X 'LAMBDA-EXPRESSION)))
           (AND (LAMBDA-EXPRESSION-P '(LAMBDA (X) X))
                (LAMBDA-EXPRESSION-P '(LAMBDA () T))
                (LAMBDA-EXPRESSION-P '(LAMBDA ()))
                (NOT (LAMBDA-EXPRESSION-P '(LAMBDA X X)))
                (NOT (LAMBDA-EXPRESSION-P 'LAMBDA))))
         T)
(DEFCLASS TEST-WALKER (WALKER) NIL)
(DEFINE-SPECIAL-FORM-WALKER ENSURE-TOPLEVEL
    ((WALKER TEST-WALKER) FORM ENV &KEY TOPLEVEL)
  (DESTRUCTURING-BIND
      (OPERATOR &OPTIONAL (ENSURE-TOPLEVEL T))
      FORM
    (DECLARE (IGNORE OPERATOR))
    (ASSERT
     (IF ENSURE-TOPLEVEL
         TOPLEVEL
         (NOT TOPLEVEL))
     (FORM ENSURE-TOPLEVEL TOPLEVEL) "~:[At~;Not at~] top level."
     ENSURE-TOPLEVEL))
  FORM)
(DEFTEST TOPLEVEL
         (LET ((WALKER (MAKE-INSTANCE 'TEST-WALKER))
               (ENV (ENSURE-PORTABLE-WALKING-ENVIRONMENT NIL)))
           (FLET ((WALK (FORM TOPLEVEL)
                    (TREE-EQUAL (WALK-FORM WALKER FORM ENV TOPLEVEL) FORM)))
             (VALUES (WALK '(ENSURE-TOPLEVEL) T)
                     (WALK '(ENSURE-TOPLEVEL NIL) NIL)
                     (WALK
                      '(LET ()
                         (ENSURE-TOPLEVEL NIL))
                      T)
                     (HANDLER-CASE (WALK '(ENSURE-TOPLEVEL) NIL)
                                   (ERROR NIL NIL))
                     (HANDLER-CASE (WALK '(ENSURE-TOPLEVEL NIL) T)
                                   (ERROR NIL NIL))
                     (HANDLER-CASE
                      (WALK
                       '(LET ()
                          (ENSURE-TOPLEVEL))
                       T)
                      (ERROR NIL NIL)))))
         T T T NIL NIL NIL)
(DEFMACRO DEFINE-WALKER-TEST
          (NAME-AND-OPTIONS FORM &OPTIONAL (RESULT NIL RESULT-SUPPLIED))
  (DESTRUCTURING-BIND
      (NAME &KEY (TOPLEVEL NIL))
      (ENSURE-LIST NAME-AND-OPTIONS)
    `(DEFTEST (WALK ,NAME)
              (LET* ((FORM ',FORM)
                     (WALKER (MAKE-INSTANCE 'TEST-WALKER))
                     (WALKED-FORM (WALK-FORM WALKER FORM NIL ,TOPLEVEL)))
                ,(COND (RESULT `(TREE-EQUAL WALKED-FORM ',RESULT))
                       ((NOT RESULT-SUPPLIED) '(TREE-EQUAL WALKED-FORM FORM))
                       (T T)))
              T)))
(DEFINE-WALKER-TEST PROGN (PROGN :FOO :BAR :BAZ))
(DEFINE-WALKER-TEST (PROGN-TOPLEVEL :TOPLEVEL T) (PROGN (ENSURE-TOPLEVEL)))
(DEFINE-WALKER-TEST BLOCK/RETURN-FROM (BLOCK :FOO (RETURN-FROM :FOO 4)))
(DEFINE-WALKER-TEST TAGBODY/GO (TAGBODY FOO (GO FOO)))
(DEFINE-WALKER-TEST CATCH/THROW (CATCH 'FOO (THROW 'FOO :FOO)))
(DEFINE-WALKER-TEST THE (THE (OR NUMBER NIL) (SQRT 4)))
(DEFINE-WALKER-TEST QUOTE-1 'FOO)
(DEFINE-WALKER-TEST QUOTE-2 '(1 2 3))
(DEFINE-WALKER-TEST (EVAL-WHEN-NON-TOPLEVEL :TOPLEVEL NIL)
 (EVAL-WHEN (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)
   (ERROR "Oops; this shouldn't have been evaluated.")))
(DEFTEST (WALK EVAL-WHEN-TOPLEVEL)
         (LET* ((STRING-OUTPUT-STREAM (MAKE-STRING-OUTPUT-STREAM))
                (*STANDARD-OUTPUT* STRING-OUTPUT-STREAM)
                (WALKER (MAKE-INSTANCE 'TEST-WALKER))
                (FORM '(EVAL-WHEN (:COMPILE-TOPLEVEL) (PRINC :FOO))))
           (AND (TREE-EQUAL (WALK-FORM WALKER FORM NIL T) FORM)
                (GET-OUTPUT-STREAM-STRING STRING-OUTPUT-STREAM)))
         "FOO")
(DEFTEST (WALK DEFCONSTANT)
         (LET ((NAME (MAKE-SYMBOL "TWO-PI")) (WALKER (MAKE-INSTANCE 'WALKER)))
           (AND (WALK-FORM WALKER `(DEFCONSTANT ,NAME (* 2 PI)) NIL T)
                (SYMBOL-VALUE NAME)))
         #.(* 2 PI))
(DEFINE-WALKER-TEST FUNCTION #'FOO)
(DEFINE-WALKER-TEST FUNCTION-SETF-FUNCTION #'(SETF FOO))
(DEFINE-WALKER-TEST FUNCTION-LAMBDA #'(LAMBDA (X) X))
(DEFTEST (PARSE-BODY 1)
         (PARSE-BODY '("doc" (DECLARE (OPTIMIZE SPEED)) :FOO :BAR)
                     :DOC-STRING-ALLOWED T)
         (:FOO :BAR) ((OPTIMIZE SPEED)) "doc")
(DEFTEST (PARSE-BODY 2)
         (PARSE-BODY
          '((DECLARE (OPTIMIZE SPEED)) "doc" (DECLARE (OPTIMIZE SPACE)) :FOO
            :BAR)
          :DOC-STRING-ALLOWED T)
         (:FOO :BAR) ((OPTIMIZE SPEED) (OPTIMIZE SPACE)) "doc")
(DEFTEST (PARSE-BODY 3) (PARSE-BODY '("doc" "string") :DOC-STRING-ALLOWED T)
         ("string") NIL "doc")
(DEFTEST (PARSE-BODY 4)
         (PARSE-BODY '((DECLARE (OPTIMIZE DEBUG)) "string") :DOC-STRING-ALLOWED
                     T)
         ("string") ((OPTIMIZE DEBUG)) NIL)
(DEFTEST (PARSE-BODY 5)
         (PARSE-BODY '((DECLARE (OPTIMIZE DEBUG)) "string") :DOC-STRING-ALLOWED
                     NIL)
         ("string") ((OPTIMIZE DEBUG)) NIL)
(DEFTEST WALK-DECLARATION-SPECIFIERS
         (EQUAL
          (WALK-DECLARATION-SPECIFIERS (MAKE-INSTANCE 'WALKER)
                                       '((TYPE FOO X) (SPECIAL X Y) (IGNORE Z)
                                         (IGNORABLE #'F)
                                         (OPTIMIZE (SPEED 3) (SAFETY 0)))
                                       NIL)
          '((SPECIAL X Y) (IGNORE Z) (IGNORABLE #'F)
            (OPTIMIZE (SPEED 3) (SAFETY 0))))
         T)
(DEFVAR *FOO* NIL "A global special variable.")
(DEFTEST WALK-BINDINGS
         (LET ((NAMES '(*FOO* BAR BAZ))
               (WALKER (MAKE-INSTANCE 'WALKER))
               (CONTEXT (MAKE-CONTEXT 'VARIABLE-NAME))
               (ENV (ENSURE-PORTABLE-WALKING-ENVIRONMENT NIL)))
           (MULTIPLE-VALUE-BIND (WALKED-NAMES NEW-ENV)
               (WALK-BINDINGS WALKER NAMES CONTEXT ENV :DECLARE
                              '((SPECIAL BAR)))
             (AND (EQUAL WALKED-NAMES NAMES)
                  (EQUAL
                   (MAPCAR (LAMBDA (VAR) (VARIABLE-INFORMATION VAR NEW-ENV))
                           NAMES)
                   '(:SPECIAL :SPECIAL :LEXICAL)))))
         T)
(DEFINE-SPECIAL-FORM-WALKER CHECK-BINDING
    ((WALKER TEST-WALKER) FORM ENV &KEY TOPLEVEL)
  (DECLARE (IGNORE TOPLEVEL))
  (FLET ((CHECK-BINDING
             (NAME NAMESPACE EXPECTED-TYPE LOCAL &AUX (ENV (AND LOCAL ENV)))
           (LET ((ACTUAL-TYPE
                  (ECASE NAMESPACE
                    (:FUNCTION (FUNCTION-INFORMATION NAME ENV))
                    (:VARIABLE (VARIABLE-INFORMATION NAME ENV)))))
             (ASSERT (EQL ACTUAL-TYPE EXPECTED-TYPE) (NAME NAMESPACE LOCAL)
                     "~:[Global~;Local~] ~(~A~) binding of ~S type ~S, not ~S."
                     LOCAL NAMESPACE NAME ACTUAL-TYPE EXPECTED-TYPE))))
    (DESTRUCTURING-BIND
        (SYMBOLS NAMESPACE TYPE &OPTIONAL (LOCAL T))
        (CDR FORM)
      (LOOP WITH SYMBOLS = (ENSURE-LIST SYMBOLS)
            FOR SYMBOL IN SYMBOLS
            DO (CHECK-BINDING SYMBOL NAMESPACE TYPE LOCAL))
      FORM)))
(DEFINE-WALKER-TEST ORDINARY-LAMBDA-LIST
 (LAMBDA
     (X Y
      &OPTIONAL
      (O
       (+ (CHECK-BINDING O :VARIABLE NIL) (CHECK-BINDING X :VARIABLE :SPECIAL)
          (CHECK-BINDING Y :VARIABLE :LEXICAL)))
      (P NIL P-SUPPLIED-P)
      &REST ARGS
      &KEY ((SECRET K) 1 K-S-P) (K2 (CHECK-BINDING K-S-P :VARIABLE :LEXICAL))
      K3 &ALLOW-OTHER-KEYS
      &AUX W
      (Z
       (IF K-S-P
           O
           X)))
   (DECLARE (SPECIAL X))
   (CHECK-BINDING X :VARIABLE :SPECIAL)
   (CHECK-BINDING (Y Z O K K-S-P K2 K3 ARGS W Z) :VARIABLE :LEXICAL)
   (CHECK-BINDING SECRET :VARIABLE NIL)))
(DEFINE-WALKER-TEST MACRO-LAMBDA-LIST
 (LAMBDA
     (&WHOLE W (X Y)
      &OPTIONAL ((O) (+ X Y))
      &KEY ((:K (K1 K2)) (2 3) K-S-P) &ENVIRONMENT ENV . BODY)
   (CHECK-BINDING (W X Y O K1 K2 K-S-P ENV BODY) :VARIABLE :LEXICAL)))
(DEFINE-WALKER-TEST LET
 (LET ((X 1) (Y (CHECK-BINDING X :VARIABLE NIL)))
   (DECLARE (SPECIAL X))
   (CHECK-BINDING X :VARIABLE :SPECIAL)
   (CHECK-BINDING Y :VARIABLE :LEXICAL)))
(DEFINE-WALKER-TEST FLET
 (FLET ((FOO (X)
          (CHECK-BINDING X :VARIABLE :LEXICAL))
        (BAR (Y)
          Y))
   (DECLARE (SPECIAL X)
            (IGNORE (FUNCTION BAR)))
   (CHECK-BINDING X :VARIABLE :SPECIAL)
   (CHECK-BINDING FOO :FUNCTION :FUNCTION)))
(DEFINE-WALKER-TEST
 (MACROLET :TOPLEVEL
   T)
 (MACROLET ((FOO (X)
              (CHECK-BINDING X :VARIABLE :LEXICAL)))
   (CHECK-BINDING FOO :FUNCTION :MACRO)
   (ENSURE-TOPLEVEL)))
(DEFINE-WALKER-TEST
 (SYMBOL-MACROLET :TOPLEVEL
   T)
 (SYMBOL-MACROLET ((FOO :FOO) (BAR :BAR))
   (CHECK-BINDING (FOO BAR) :VARIABLE :SYMBOL-MACRO)
   (ENSURE-TOPLEVEL)
   FOO
   BAR)
 (SYMBOL-MACROLET ((FOO :FOO) (BAR :BAR))
   (CHECK-BINDING (FOO BAR) :VARIABLE :SYMBOL-MACRO)
   (ENSURE-TOPLEVEL)
   :FOO
   :BAR))
(DEFINE-WALKER-TEST LET*
 (LET* ((X 1) (Y (CHECK-BINDING X :VARIABLE :SPECIAL)))
   (DECLARE (SPECIAL X))
   (CHECK-BINDING Y :VARIABLE :LEXICAL)))
(DEFINE-WALKER-TEST LABELS
 (LABELS ((FOO (X)
            (CHECK-BINDING X :VARIABLE :LEXICAL))
          (BAR (Y)
            (CHECK-BINDING FOO :FUNCTION :FUNCTION)))
   (DECLARE (SPECIAL X))
   (CHECK-BINDING X :VARIABLE :SPECIAL)
   (CHECK-BINDING FOO :FUNCTION :FUNCTION)))
(DEFINE-WALKER-TEST (LOCALLY :TOPLEVEL T)
 (LOCALLY
  NIL
  (ENSURE-TOPLEVEL)
  (LET ((Y T))
    (CHECK-BINDING Y :VARIABLE :LEXICAL)
    (LOCALLY
     (DECLARE (SPECIAL Y))
     (ENSURE-TOPLEVEL NIL)
     (CHECK-BINDING Y :VARIABLE :SPECIAL)))))
(DEFINE-WALKER-TEST
 (DECLAIM :TOPLEVEL
          T)
 (PROGN (DECLAIM (SPECIAL *FOO*)) (CHECK-BINDING *FOO* :VARIABLE :SPECIAL NIL)))
(DEFTEST (WALK DEFINE-SYMBOL-MACRO)
         (LET ((WALKER (MAKE-INSTANCE 'TEST-WALKER)) (NAME (GENSYM)))
           (EVAL `(DEFINE-SYMBOL-MACRO ,NAME (ENSURE-TOPLEVEL)))
           (NOT
            (NULL
             (WALK-FORM WALKER
                        `(CHECK-BINDING ,NAME :VARIABLE :SYMBOL-MACRO NIL) NIL
                        T))))
         T)
(DEFCLASS TRACING-WALKER (WALKER) NIL)
(DEFMETHOD WALK-ATOMIC-FORM :BEFORE
           ((WALKER TRACING-WALKER) FORM CONTEXT ENV &KEY TOPLEVEL)
  (DECLARE (IGNORE ENV))
  (FORMAT *TRACE-OUTPUT*
          "~&~@<; ~@;walking~:[~; toplevel~] atomic form ~S ~S~:>~%" TOPLEVEL
          FORM CONTEXT))
(DEFMETHOD WALK-COMPOUND-FORM :BEFORE
           ((WALKER TRACING-WALKER) OPERATOR FORM ENV &KEY TOPLEVEL)
  (DECLARE (IGNORE OPERATOR ENV))
  (FORMAT *TRACE-OUTPUT*
          "~&~@<; ~@;walking~:[~; toplevel~] compound form ~W~:>~%" TOPLEVEL
          FORM))
(DEFMETHOD WALK-NAME :BEFORE
           ((WALKER TRACING-WALKER) NAME CONTEXT ENV &REST ARGS)
  (DECLARE (IGNORE ENV))
  (FORMAT *TRACE-OUTPUT* "~&~@<; ~@;walking name ~S ~S~@[~S~]~:>~%" NAME
          CONTEXT ARGS))
(DEFMETHOD WALK-BINDINGS :BEFORE
           ((WALKER TRACING-WALKER) NAMES CONTEXT ENV &KEY DECLARE)
  (DECLARE (IGNORE ENV DECLARE))
  (FORMAT *TRACE-OUTPUT* "~&~@<; ~@;walking bindings ~S ~S~:>~%" NAMES CONTEXT))
(DEFTEST INDEX-PACKAGE
         (LET ((*INDEX-PACKAGES* NIL))
           (INDEX-PACKAGE "KEYWORD")
           (VALUES (INTERESTING-SYMBOL-P 'NIL)
                   (NOT (NULL (INTERESTING-SYMBOL-P ':FOO)))))
         NIL T)
(INDEX-PACKAGE "CLWEB")
(DEFTEST HEADING-NAME (HEADING-NAME (MAKE-HEADING "foo" (MAKE-HEADING "bar")))
         "foo bar")
(DEFTEST (HEADING-NAME CHARACTER) (HEADING-NAME #\A) "A")
(DEFTEST (HEADING-NAME STRING) (HEADING-NAME "\\foo") "foo")
(DEFTEST (HEADING-NAME SYMBOL)
         (VALUES (HEADING-NAME :FOO) (HEADING-NAME '|\\foo|)) "FOO" "\\foo")
(DEFUN ENTRY-HEADING-STRICTLY-LESSP (X Y)
  (AND (ENTRY-HEADING-LESSP X Y) (NOT (ENTRY-HEADING-LESSP Y X))))
(DEFTEST ENTRY-HEADING-LESSP
         (LET* ((A (MAKE-HEADING "a"))
                (B (MAKE-HEADING "b"))
                (X (MAKE-HEADING "x"))
                (Y (MAKE-HEADING "y"))
                (AX (MAKE-HEADING "a" X))
                (AY (MAKE-HEADING "a" Y))
                (BX (MAKE-HEADING "b" X))
                (BY (MAKE-HEADING "a" Y)))
           (EVERY #'IDENTITY
                  (LIST (NOT (ENTRY-HEADING-STRICTLY-LESSP A A))
                        (ENTRY-HEADING-STRICTLY-LESSP A B)
                        (ENTRY-HEADING-STRICTLY-LESSP A AX)
                        (ENTRY-HEADING-STRICTLY-LESSP AX AY)
                        (ENTRY-HEADING-STRICTLY-LESSP AX BX)
                        (ENTRY-HEADING-STRICTLY-LESSP AY BX)
                        (ENTRY-HEADING-STRICTLY-LESSP AX BY))))
         T)
(DEFUN ENTRY-HEADING-SYMMETRIC-EQUALP (X Y)
  (AND (ENTRY-HEADING-EQUALP X Y) (ENTRY-HEADING-EQUALP Y X)))
(DEFUN ENTRY-HEADING-SYMMETRIC-UNEQUALP (X Y)
  (AND (NOT (ENTRY-HEADING-EQUALP X Y)) (NOT (ENTRY-HEADING-EQUALP Y X))))
(DEFTEST ENTRY-HEADING-EQUALP
         (LET* ((A (MAKE-HEADING "a"))
                (B (MAKE-HEADING "b"))
                (X (MAKE-HEADING "x"))
                (Y (MAKE-HEADING "y"))
                (AX (MAKE-HEADING "a" X))
                (AY (MAKE-HEADING "a" Y)))
           (EVERY #'IDENTITY
                  (LIST (ENTRY-HEADING-SYMMETRIC-EQUALP A A)
                        (ENTRY-HEADING-SYMMETRIC-UNEQUALP A B)
                        (ENTRY-HEADING-SYMMETRIC-EQUALP AX AX)
                        (ENTRY-HEADING-SYMMETRIC-UNEQUALP AX AY))))
         T)
(DEFMETHOD PRINT-OBJECT ((HEADING HEADING) STREAM)
  (PRINT-UNREADABLE-OBJECT (HEADING STREAM :TYPE T :IDENTITY NIL)
    (FORMAT STREAM "\"~A\"" (HEADING-NAME HEADING))))
(DEFTEST JOIN-STRINGS
         (VALUES (JOIN-STRINGS "foo") (JOIN-STRINGS '("foo" "bar"))
                 (JOIN-STRINGS '(:FOO :BAR NIL :BAZ) #\,))
         "foo" "foo bar" "FOO,BAR,BAZ")
(DEFCLASS DEAD-BEEF NIL NIL)
(DEFCLASS KOBE-BEEF (DEAD-BEEF) NIL)
(DEFCLASS ROTTEN-BEEF (DEAD-BEEF) NIL)
(DEFGENERIC DESCRIBE-BEEF
    (BEEF)
  (:METHOD-COMBINATION JOIN-STRINGS ", ")
  (:METHOD ((BEEF DEAD-BEEF)) "steak")
  (:METHOD :PREFIX ((BEEF DEAD-BEEF)) (LIST "big" "fat" "juicy"))
  (:METHOD :SUFFIX ((BEEF DEAD-BEEF)) "yum!")
  (:METHOD :PREFIX ((BEEF KOBE-BEEF)) "delicious")
  (:METHOD ((BEEF KOBE-BEEF)) "Kobe")
  (:METHOD :SUFFIX ((BEEF KOBE-BEEF)) "from Japan")
  (:METHOD :OVERRIDE ((BEEF ROTTEN-BEEF)) "Yuck!"))
(DEFTEST JOIN-STRINGS-METHOD-COMBINATION
         (VALUES (DESCRIBE-BEEF (MAKE-INSTANCE 'DEAD-BEEF))
                 (DESCRIBE-BEEF (MAKE-INSTANCE 'KOBE-BEEF))
                 (DESCRIBE-BEEF (MAKE-INSTANCE 'ROTTEN-BEEF)))
         "big, fat, juicy, steak, yum!"
         "delicious, big, fat, juicy, Kobe, steak, yum!, from Japan" "Yuck!")
(DEFTEST FUNCTION-HEADING-NAME
         (VALUES (HEADING-NAME (MAKE-CONTEXT 'FUNCTION-NAME))
                 (HEADING-NAME (MAKE-CONTEXT 'FUNCTION-NAME :LOCAL T))
                 (HEADING-NAME (MAKE-CONTEXT 'GENERIC-FUNCTION-NAME))
                 (HEADING-NAME (MAKE-CONTEXT 'SETF-FUNCTION-NAME))
                 (HEADING-NAME (MAKE-CONTEXT 'SETF-FUNCTION-NAME :LOCAL T)))
         "function" "local function" "generic function" "setf function"
         "local setf function")
(DEFTEST METHOD-HEADING-NAME
         (VALUES (HEADING-NAME (MAKE-CONTEXT 'METHOD-NAME))
                 (HEADING-NAME
                  (MAKE-CONTEXT 'METHOD-NAME :QUALIFIERS
                                '(:BEFORE :DURING :AFTER))))
         "primary method" "before during after method")
(DEFMETHOD PRINT-OBJECT ((ENTRY INDEX-ENTRY) STREAM)
  (PRINT-UNREADABLE-OBJECT (ENTRY STREAM :TYPE T :IDENTITY NIL)
    (FORMAT STREAM "~W:" (ENTRY-HEADING ENTRY))
    (DOLIST
        (LOCATOR
         (SORT (COPY-LIST (ENTRY-LOCATORS ENTRY)) #'< :KEY
               (LAMBDA (X) (SECTION-NUMBER (LOCATION X)))))
      (FORMAT STREAM " ~:[~D~;[~D]~]" (LOCATOR-DEFINITION-P LOCATOR)
              (SECTION-NUMBER (LOCATION LOCATOR))))))
(DEFTEST (ADD-INDEX-ENTRY 1)
         (LET ((INDEX (MAKE-INDEX)) (HEADING 'FOO))
           (ADD-INDEX-ENTRY INDEX HEADING 1)
           (ADD-INDEX-ENTRY INDEX HEADING 2)
           (ADD-INDEX-ENTRY INDEX HEADING 3)
           (SORT (MAPCAR #'LOCATION (FIND-INDEX-ENTRIES INDEX HEADING)) #'<))
         (1 2 3))
(DEFTEST (ADD-INDEX-ENTRY 2)
         (LET* ((INDEX (MAKE-INDEX)) (HEADING 'FOO))
           (ADD-INDEX-ENTRY INDEX HEADING 1)
           (ADD-INDEX-ENTRY INDEX HEADING 1 T)
           (LOCATOR-DEFINITION-P (FIRST (FIND-INDEX-ENTRIES INDEX HEADING))))
         T)
(DEFTEST (SYMBOL-PROVENANCE 1)
         (LET ((*INDEX-PACKAGES* (LIST (FIND-PACKAGE "KEYWORD"))))
           (SYMBOL-PROVENANCE (SUBSTITUTE-REFERRING-SYMBOLS :FOO 1)))
         :FOO 1)
(DEFTEST (SYMBOL-PROVENANCE 2) (SYMBOL-PROVENANCE :FOO) :FOO)
(DEFTEST (SYMBOL-PROVENANCE 3)
         (LET ((SYMBOL (MAKE-SYMBOL "FOO")))
           (EQL (SYMBOL-PROVENANCE SYMBOL) SYMBOL))
         T)
(DEFTEST (SYMBOL-PROVENANCE 4)
         (LET ((*INDEX-PACKAGES* (LIST (FIND-PACKAGE "KEYWORD"))))
           (SYMBOL-PROVENANCE
            (MACROEXPAND
             (SUBSTITUTE-REFERRING-SYMBOLS
              (TANGLE (READ-FORM-FROM-STRING "`,:foo")) 1))))
         :FOO 1)
(DEFUN ALL-INDEX-ENTRIES (INDEX)
  (LET ((ENTRIES))
    (MAP-BST
     (LAMBDA (ENTRY)
       (PUSH
        (LIST (HEADING-NAME (ENTRY-HEADING ENTRY))
              (LOOP FOR LOCATOR IN (ENTRY-LOCATORS ENTRY)
                    IF (LOCATOR-DEFINITION-P LOCATOR)
                    COLLECT `(:DEF ,(SECTION-NUMBER (LOCATION LOCATOR))) ELSE
                    COLLECT (SECTION-NUMBER (LOCATION LOCATOR))))
        ENTRIES))
     (INDEX-ENTRIES INDEX))
    (NREVERSE ENTRIES)))
(DEFUN WALK-SECTIONS (WALKER SECTIONS ENV &KEY (VERIFY-WALK T) TOPLEVEL)
  (WITH-TEMPORARY-SECTIONS SECTIONS
   (LET ((TANGLED-CODE (TANGLE (UNNAMED-SECTION-CODE-PARTS *SECTIONS*)))
         (MANGLED-CODE (TANGLE-CODE-FOR-INDEXING *SECTIONS*)))
     (LOOP FOR FORM IN TANGLED-CODE
           AND MANGLED-FORM IN MANGLED-CODE AS WALKED-FORM = (WALK-FORM WALKER
                                                                        MANGLED-FORM
                                                                        ENV
                                                                        TOPLEVEL)
           WHEN VERIFY-WALK
           DO (ASSERT (TREE-EQUAL WALKED-FORM FORM)
                      (WALKED-FORM MANGLED-FORM FORM)
                      "Walked form does not match original.")
           COLLECT WALKED-FORM))))
(DEFCLASS TRACING-INDEXING-WALKER (TRACING-WALKER INDEXING-WALKER) NIL)
(DEFUN TEST-INDEXING-WALK
       (SECTIONS EXPECTED-ENTRIES ENV
        &KEY (VERIFY-WALK T) TOPLEVEL INDEX-LEXICALS TRACE PRINT)
  (LET* ((WALKER
          (MAKE-INSTANCE
           (IF TRACE
               'TRACING-INDEXING-WALKER
               'INDEXING-WALKER)))
         (*INDEX-LEXICAL-VARIABLES* INDEX-LEXICALS)
         (WALKED-SECTIONS
          (WALK-SECTIONS WALKER SECTIONS ENV :VERIFY-WALK VERIFY-WALK :TOPLEVEL
           TOPLEVEL)))
    (WHEN PRINT (PPRINT WALKED-SECTIONS))
    (LET ((ENTRIES (ALL-INDEX-ENTRIES (WALKER-INDEX WALKER))))
      (WHEN PRINT (PPRINT ENTRIES))
      (TREE-EQUAL ENTRIES EXPECTED-ENTRIES :TEST #'EQUAL))))
(DEFMACRO WITH-UNIQUE-INDEXING-NAMES (NAMES &BODY BODY)
  `(LET* ((TEMP-PACKAGE (MAKE-PACKAGE "INDEX-TEMP"))
          (*INDEX-PACKAGES* (CONS TEMP-PACKAGE *INDEX-PACKAGES*))
          ,@(LOOP FOR NAME IN NAMES
                  COLLECT `(,NAME (INTERN ,(STRING NAME) TEMP-PACKAGE))))
     (UNWIND-PROTECT (PROGN ,@BODY) (DELETE-PACKAGE TEMP-PACKAGE))))
(DEFMACRO DEFINE-INDEXING-TEST
          (NAME-AND-OPTIONS SECTIONS &REST EXPECTED-ENTRIES)
  (DESTRUCTURING-BIND
      (NAME &REST OPTIONS &KEY AUX &ALLOW-OTHER-KEYS)
      (IF (LISTP NAME-AND-OPTIONS)
          (COPY-LIST NAME-AND-OPTIONS)
          (LIST NAME-AND-OPTIONS))
    (REMF OPTIONS :AUX)
    `(DEFTEST (INDEX ,@(ENSURE-LIST NAME))
              (WITH-UNIQUE-INDEXING-NAMES ,AUX
               (TEST-INDEXING-WALK ,SECTIONS ',EXPECTED-ENTRIES NIL ,@OPTIONS))
              T)))
(DEFINE-INDEXING-TEST QUOTED-FORM
 '((:SECTION :CODE ('FOO)) (:SECTION :CODE ('(FOO BAR)))))
(DEFINE-INDEXING-TEST (LEXICAL-VARIABLE :INDEX-LEXICALS T)
 '((:SECTION :CODE
    ((LET ((X NIL) (Y NIL) (Z NIL))
       ))))
 ("X lexical variable" ((:DEF 0))) ("Y lexical variable" ((:DEF 0)))
 ("Z lexical variable" ((:DEF 0))))
(DEFINE-INDEXING-TEST SPECIAL-VARIABLE
 '((:SECTION :CODE ((LOCALLY (DECLARE (SPECIAL *X*)) *X*))))
 ("*X* special variable" (0)))
(DEFINE-INDEXING-TEST
 (MACROLET :VERIFY-WALK
   NIL)
 '((:SECTION :CODE
    ((MACROLET ((FROB (X)
                  `(* ,X 42)))
       (FROB 6)))))
 ("FROB local macro" ((:DEF 0))))
(DEFINE-INDEXING-TEST
 (SYMBOL-MACROLET :VERIFY-WALK
   NIL)
 '((:SECTION :CODE
    ((SYMBOL-MACROLET ((FOO :BAR))
       FOO))))
 ("FOO local symbol macro" ((:DEF 0))))
(DEFINE-INDEXING-TEST CATCH/THROW
 '((:SECTION :CODE ((CATCH 'FOO (THROW 'BAR (THROW (LAMBDA () 'BAZ) T))))))
 ("BAR catch tag" (0)) ("FOO catch tag" ((:DEF 0))))
(DEFVAR *SUPER* T)
(DEFINE-SYMBOL-MACRO BAIT SWITCH)
(DEFCONSTANT THE-ULTIMATE-ANSWER 42)
(DEFINE-INDEXING-TEST (VARIABLES :VERIFY-WALK NIL)
 '((:SECTION :CODE (*SUPER*)) (:SECTION :CODE (BAIT))
   (:SECTION :CODE (THE-ULTIMATE-ANSWER)))
 ("*SUPER* special variable" (0)) ("BAIT symbol macro" (1))
 ("THE-ULTIMATE-ANSWER constant" (2)))
(DEFUN SQUARE (X) (* X X))
(DEFINE-INDEXING-TEST FUNCTION '((:SECTION :CODE ((SQUARE 1))))
 ("SQUARE function" (0)))
(DEFMACRO FROB-FOO (FOO) `(1+ (* ,FOO 42)))
(DEFINE-INDEXING-TEST (MACRO :VERIFY-WALK NIL)
 '((:SECTION :CODE ((FROB-FOO 6)))) ("FROB-FOO macro" (0)))
(DEFINE-INDEXING-TEST FUNCTION-NAME
 '((:SECTION :CODE ((FLET ((FOO (X) X)))))
   (:SECTION :CODE ((LABELS (((SETF FOO) (Y X) Y))))))
 ("FOO local function" ((:DEF 0))) ("FOO local setf function" ((:DEF 1))))
(DEFINE-INDEXING-TEST (DEFUN :VERIFY-WALK ())
 '((:SECTION :CODE ((DEFUN FOO (X) X)))) ("FOO function" ((:DEF 0))))
(DEFINE-INDEXING-TEST
 (DEFINE-COMPILER-MACRO :VERIFY-WALK
     NIL
   :TOPLEVEL
   T
   :AUX
   (COMPILE-FOO))
 `((:SECTION :CODE
    ((DEFINE-COMPILER-MACRO ,COMPILE-FOO
         (&WHOLE X)
       X))))
 ("COMPILE-FOO compiler macro" ((:DEF 0))))
(DEFINE-INDEXING-TEST
 (DEFMACRO :VERIFY-WALK () :TOPLEVEL T :AUX (TWIDDLE TWIDDLE-FOO))
 `((:SECTION :CODE
    ((EVAL-WHEN (:COMPILE-TOPLEVEL) (DEFUN ,TWIDDLE (X) (* X 42)))))
   (:SECTION :CODE
    ((EVAL-WHEN (:COMPILE-TOPLEVEL) (DEFMACRO ,TWIDDLE-FOO (X) (,TWIDDLE X)))))
   (:SECTION :CODE ((,TWIDDLE-FOO 123))))
 ("TWIDDLE function" (1 (:DEF 0))) ("TWIDDLE-FOO macro" (2 (:DEF 1))))
(DEFINE-INDEXING-TEST
 (SYMBOL-MACRO :VERIFY-WALK NIL :TOPLEVEL T :AUX (FOO-BAR-BAZ))
 `((:SECTION :CODE
    ((EVAL-WHEN (:COMPILE-TOPLEVEL)
       (DEFINE-SYMBOL-MACRO ,FOO-BAR-BAZ (:BAR :BAZ)))))
   (:SECTION :CODE (,FOO-BAR-BAZ)))
 ("FOO-BAR-BAZ symbol macro" (1 (:DEF 0))))
(DEFINE-INDEXING-TEST (DEFVAR :VERIFY-WALK NIL :TOPLEVEL T :AUX (SUPER DUPER))
 `((:SECTION :CODE ((EVAL-WHEN (:COMPILE-TOPLEVEL) (DEFVAR ,SUPER 450))))
   (:SECTION :CODE
    ((EVAL-WHEN (:COMPILE-TOPLEVEL) (DEFPARAMETER ,DUPER (1+ ,SUPER))))))
 ("DUPER special variable" ((:DEF 1))) ("SUPER special variable" (1 (:DEF 0))))
(DEFINE-INDEXING-TEST
 (DEFCONSTANT :VERIFY-WALK NIL :TOPLEVEL T :AUX (EL-GORDO))
 `((:SECTION :CODE ((DEFCONSTANT ,EL-GORDO MOST-POSITIVE-FIXNUM))))
 ("EL-GORDO constant" ((:DEF 0))))
(DEFINE-INDEXING-TEST (DEFSTRUCT :VERIFY-WALK NIL :TOPLEVEL T :AUX (FOO))
 `((:SECTION :CODE ((DEFSTRUCT ,FOO)))) ("COPY-FOO copier function" ((:DEF 0)))
 ("FOO structure" ((:DEF 0))) ("FOO-P type predicate" ((:DEF 0)))
 ("MAKE-FOO constructor function" ((:DEF 0))))
(DEFINE-INDEXING-TEST
 ((DEFSTRUCT FUNCTIONS) :VERIFY-WALK NIL :TOPLEVEL T :AUX
  (A B C CONS-C DUP-C CP))
 `((:SECTION :CODE ((DEFSTRUCT (,A :CONSTRUCTOR (:PREDICATE NIL)))))
   (:SECTION :CODE ((DEFSTRUCT (,B (:CONSTRUCTOR NIL) (:PREDICATE)))))
   (:SECTION :CODE
    ((DEFSTRUCT
         (,C (:CONSTRUCTOR ,CONS-C) (:COPIER ,DUP-C) (:PREDICATE ,CP))))))
 ("A structure" ((:DEF 0))) ("B structure" ((:DEF 1)))
 ("B-P type predicate" ((:DEF 1))) ("C structure" ((:DEF 2)))
 ("CONS-C constructor function" ((:DEF 2)))
 ("COPY-A copier function" ((:DEF 0))) ("COPY-B copier function" ((:DEF 1)))
 ("CP type predicate" ((:DEF 2))) ("DUP-C copier function" ((:DEF 2)))
 ("MAKE-A constructor function" ((:DEF 0))))
(DEFINE-INDEXING-TEST
 ((DEFSTRUCT :INCLUDE) :VERIFY-WALK NIL :TOPLEVEL T :AUX (BASE DERIVED))
 `((:SECTION :CODE
    ((EVAL-WHEN (:COMPILE-TOPLEVEL)
       (DEFSTRUCT (,BASE (:CONSTRUCTOR NIL) (:COPIER NIL) (:PREDICATE NIL))))))
   (:SECTION :CODE
    ((EVAL-WHEN (:COMPILE-TOPLEVEL)
       (DEFSTRUCT
           (,DERIVED (:INCLUDE ,BASE) (:CONSTRUCTOR NIL) (:COPIER NIL)
            (:PREDICATE NIL)))))))
 ("BASE structure" (1 (:DEF 0))) ("DERIVED structure" ((:DEF 1))))
(DEFINE-INDEXING-TEST
 ((DEFSTRUCT ACCESSORS) :VERIFY-WALK NIL :TOPLEVEL T :AUX (TOWN))
 `((:SECTION :CODE
    ((DEFSTRUCT ,TOWN
       AREA
       WATERTOWERS
       (FIRETRUCKS 1 :TYPE FIXNUM)
       POPULATION
       (ELEVATION 5128 :READ-ONLY T)))))
 ("COPY-TOWN copier function" ((:DEF 0)))
 ("MAKE-TOWN constructor function" ((:DEF 0))) ("TOWN structure" ((:DEF 0)))
 ("TOWN-AREA slot accessor" ((:DEF 0)))
 ("TOWN-ELEVATION slot reader" ((:DEF 0)))
 ("TOWN-FIRETRUCKS slot accessor" ((:DEF 0)))
 ("TOWN-P type predicate" ((:DEF 0)))
 ("TOWN-POPULATION slot accessor" ((:DEF 0)))
 ("TOWN-WATERTOWERS slot accessor" ((:DEF 0))))
(DEFINE-INDEXING-TEST
 ((DEFSTRUCT CONC-NAME) :VERIFY-WALK NIL :TOPLEVEL T :AUX (CLOWN))
 `((:SECTION :CODE
    ((DEFSTRUCT (,CLOWN (:CONC-NAME BOZO-))
       (NOSE-COLOR 'RED)
       FRIZZY-HAIR-P
       POLKADOTS))))
 ("BOZO-FRIZZY-HAIR-P slot accessor" ((:DEF 0)))
 ("BOZO-NOSE-COLOR slot accessor" ((:DEF 0)))
 ("BOZO-POLKADOTS slot accessor" ((:DEF 0))) ("CLOWN structure" ((:DEF 0)))
 ("CLOWN-P type predicate" ((:DEF 0)))
 ("COPY-CLOWN copier function" ((:DEF 0)))
 ("MAKE-CLOWN constructor function" ((:DEF 0))))
(DEFINE-INDEXING-TEST
 ((DEFSTRUCT INHERITED-ACCESSOR) :VERIFY-WALK NIL :TOPLEVEL T :AUX (A B))
 `((:SECTION :CODE
    ((EVAL-WHEN (:COMPILE-TOPLEVEL)
       (DEFSTRUCT
           (,A (:CONC-NAME NIL) (:CONSTRUCTOR NIL) (:COPIER NIL)
            (:PREDICATE NIL))
         A-B))))
   (:SECTION :CODE
    ((EVAL-WHEN (:COMPILE-TOPLEVEL)
       (DEFSTRUCT
           (,B (:INCLUDE ,A) (:CONC-NAME A-) (:CONSTRUCTOR NIL) (:COPIER NIL)
            (:PREDICATE NIL))
         (B NIL :READ-ONLY T))))))
 ("A structure" (1 (:DEF 0))) ("A-B slot accessor" ((:DEF 0)))
 ("B structure" ((:DEF 1))))
(DEFINE-INDEXING-TEST
 (DEFGENERIC :AUX
     (FOO))
 `((:SECTION :CODE
    ((DEFGENERIC ,FOO
         (X Y)
       (:DOCUMENTATION "foo")
       (:METHOD-COMBINATION PROGN)
       (:METHOD PROGN ((X T) Y) X)
       (:METHOD :AROUND (X (Y (EQL 'T))) Y))))
   (:SECTION :CODE ((,FOO 2 3)))
   (:SECTION :CODE
    ((DEFGENERIC (SETF ,FOO)
         (NEW X Y)))))
 ("FOO around method" ((:DEF 0))) ("FOO generic function" (1 (:DEF 0)))
 ("FOO generic setf function" ((:DEF 2))) ("FOO progn method" ((:DEF 0))))
(DEFTEST GENERIC-FUNCTION-P
         (VALUES (NOT (NULL (GENERIC-FUNCTION-P 'MAKE-INSTANCE)))
                 (NULL (GENERIC-FUNCTION-P '#:FOO))
                 (NOT
                  (NULL (GENERIC-FUNCTION-P (NOTE-GENERIC-FUNCTION '#:FOO)))))
         T T T)
(DEFMETHOD PRINT-OBJECT ((X METHOD-NAME) STREAM)
  (PRINT-UNREADABLE-OBJECT (X STREAM :TYPE T :IDENTITY T)
    (PRIN1 (METHOD-QUALIFIER-NAMES X) STREAM)))
(DEFINE-INDEXING-TEST (DEFMETHOD :AUX (FOO))
 `((:SECTION :CODE ((DEFMETHOD ,FOO (X Y) (+ X Y))))
   (:SECTION :CODE ((DEFMETHOD ,FOO :BEFORE (X Y))))
   (:SECTION :CODE ((DEFMETHOD (SETF ,FOO) (NEW-FOO FOO) NEW-FOO)))
   (:SECTION :CODE ((FUNCALL #'(SETF ,FOO) Y X))))
 ("FOO before method" ((:DEF 1))) ("FOO generic setf function" (3))
 ("FOO primary method" ((:DEF 0))) ("FOO primary setf method" ((:DEF 2))))
(DEFINE-INDEXING-TEST
 (DEFCLASS :VERIFY-WALK NIL :AUX (FOO BAR A B FOO-A1 FOO-A2 FOO-B))
 `((:SECTION :CODE
    ((DEFCLASS ,FOO NIL ((,A :READER ,FOO-A1 :READER ,FOO-A2)))))
   (:SECTION :CODE
    ((DEFINE-CONDITION ,BAR
         NIL
         ((,B :ACCESSOR ,FOO-B))))))
 ("BAR condition class" ((:DEF 1))) ("FOO class" ((:DEF 0)))
 ("FOO-A1 reader method" ((:DEF 0))) ("FOO-A2 reader method" ((:DEF 0)))
 ("FOO-B accessor method" ((:DEF 1))))
(DEFINE-INDEXING-TEST
 (DEFINE-METHOD-COMBINATION :VERIFY-WALK NIL :AUX (FOO GENERIC-FOO))
 `((:SECTION :CODE ((DEFINE-METHOD-COMBINATION ,FOO)))
   (:SECTION :CODE
    ((DEFGENERIC ,GENERIC-FOO
         NIL
       (:METHOD-COMBINATION ,FOO)))))
 ("FOO method combination" (1 (:DEF 0)))
 ("GENERIC-FOO generic function" ((:DEF 1))))
(DEFMETHOD LOCATION ((RANGE SECTION-RANGE))
  (LIST (START-SECTION RANGE) (END-SECTION RANGE)))
(DEFTEST (COALESCE-LOCATORS 1)
         (MAPCAR
          (LAMBDA (SECTIONS)
            (MAPCAR #'LOCATION
                    (COALESCE-LOCATORS
                     (MAPCAR
                      (LAMBDA (N) (MAKE-INSTANCE 'SECTION-LOCATOR :SECTION N))
                      SECTIONS))))
          '((1 3 5 7) (1 2 3 5 7) (1 3 4 5 7) (1 2 3 5 6 7) (1 2 3 5 6 7 9)))
         ((1 3 5 7) ((1 3) 5 7) (1 (3 5) 7) ((1 3) (5 7)) ((1 3) (5 7) 9)))
(DEFTEST (COALESCE-LOCATORS 2)
         (MAPCAR #'LOCATION
                 (COALESCE-LOCATORS
                  `(,(MAKE-INSTANCE 'SECTION-LOCATOR :SECTION 1 :DEF T)
                    ,@(MAPCAR
                       (LAMBDA (N) (MAKE-INSTANCE 'SECTION-LOCATOR :SECTION N))
                       '(2 3 5))
                    ,(MAKE-INSTANCE 'SECTION-LOCATOR :SECTION 6 :DEF T))))
         (1 (2 3) 5 6))
(DEFTEST MACRO-CHAR-HEADING-LESSP
         (LET* ((A (MAKE-MACRO-CHAR-HEADING #\a))
                (B (MAKE-MACRO-CHAR-HEADING #\b))
                (AB (MAKE-MACRO-CHAR-HEADING #\a #\b))
                (AC (MAKE-MACRO-CHAR-HEADING #\a #\c)))
           (EVERY #'IDENTITY
                  (LIST (ENTRY-HEADING-STRICTLY-LESSP A B)
                        (NOT (ENTRY-HEADING-STRICTLY-LESSP B A))
                        (ENTRY-HEADING-STRICTLY-LESSP A AB)
                        (ENTRY-HEADING-STRICTLY-LESSP B AB)
                        (NOT (ENTRY-HEADING-STRICTLY-LESSP AB AB))
                        (ENTRY-HEADING-STRICTLY-LESSP AB AC))))
         T)
(DEFTEST MACRO-CHAR-HEADING-EQUALP
         (LET* ((A (MAKE-MACRO-CHAR-HEADING #\a))
                (B (MAKE-MACRO-CHAR-HEADING #\b))
                (AB (MAKE-MACRO-CHAR-HEADING #\a #\b)))
           (EVERY #'IDENTITY
                  (LIST (ENTRY-HEADING-SYMMETRIC-EQUALP A A)
                        (ENTRY-HEADING-SYMMETRIC-UNEQUALP A B)
                        (ENTRY-HEADING-SYMMETRIC-UNEQUALP B A)
                        (ENTRY-HEADING-SYMMETRIC-UNEQUALP A AB)
                        (ENTRY-HEADING-SYMMETRIC-EQUALP AB AB))))
         T)
(DEFINE-INDEXING-TEST MACRO-CHARACTER
 '((:SECTION :CODE ((SET-MACRO-CHARACTER #\! '#:READ-BANG)))
   (:SECTION :CODE ((SET-DISPATCH-MACRO-CHARACTER #\@ #\! '#:READ-AT-BANG))))
 ("!" ((:DEF 0))) ("@ !" ((:DEF 1))))