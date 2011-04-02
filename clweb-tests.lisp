;;;; TANGLED WEB FROM "clweb.clw". DO NOT EDIT.
#+ALLEGRO
(EVAL-WHEN (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL)
  (SETQ EXCL:*SOURCE-PATHNAME* #P"clweb.clw"))

(IN-PACKAGE "CLWEB")
(EVAL-WHEN (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)
  (REQUIRE "RT")
  (DO-EXTERNAL-SYMBOLS (SYMBOL (FIND-PACKAGE "RT")) (IMPORT SYMBOL)))
(DEFMETHOD SECTION-NUMBER ((SECTION INTEGER)) SECTION)
(DEFTEST CURRENT-SECTION
         (LET ((*SECTIONS* (MAKE-ARRAY 1 :FILL-POINTER 0)))
           (EQL (MAKE-INSTANCE 'SECTION) *CURRENT-SECTION*))
         T)
(DEFMACRO WITH-TEMPORARY-SECTIONS
          (SECTIONS
           &BODY BODY
           &AUX (SPEC (GENSYM)) (SECTION (GENSYM)) (NAME (GENSYM)))
  `(LET ((*SECTIONS* (MAKE-ARRAY 16 :ADJUSTABLE T :FILL-POINTER 0))
         (*TEST-SECTIONS* (MAKE-ARRAY 16 :ADJUSTABLE T :FILL-POINTER 0))
         (*NAMED-SECTIONS* NIL))
     (DOLIST (,SPEC ',SECTIONS)
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
     ,@BODY))
(DEFTEST (BST 1)
         (LET ((TREE (MAKE-INSTANCE 'BINARY-SEARCH-TREE :KEY 0)))
           (FIND-OR-INSERT -1 TREE)
           (FIND-OR-INSERT 1 TREE)
           (VALUES (NODE-KEY TREE) (NODE-KEY (LEFT-CHILD TREE))
                   (NODE-KEY (RIGHT-CHILD TREE))))
         0 -1 1)
(DEFTEST (BST 2)
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
(DEFTEST BST-FIND-NO-INSERT
         (LET ((TREE (MAKE-INSTANCE 'BINARY-SEARCH-TREE :KEY 0)))
           (FIND-OR-INSERT -1 TREE :INSERT-IF-NOT-FOUND NIL))
         NIL NIL)
(DEFTEST NAMED-SECTION-NUMBER/CODE
         (WITH-TEMPORARY-SECTIONS
          ((:SECTION :NAME "foo" :CODE (1)) (:SECTION :NAME "foo" :CODE (2))
           (:SECTION :NAME "foo" :CODE (3)))
          (LET ((SECTION (FIND-SECTION "foo")))
            (VALUES (SECTION-CODE SECTION) (SECTION-NUMBER SECTION))))
         (1 2 3) 0)
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
   ((:SECTION :NAME "bar" :CODE (:BAR)) (:SECTION :NAME "baz" :CODE (:BAZ))
    (:SECTION :NAME "foo" :CODE (:FOO)) (:SECTION :NAME "qux" :CODE (:QUX)))
   *NAMED-SECTIONS*))
(DEFUN FIND-SAMPLE-SECTION (NAME)
  (FIND-OR-INSERT NAME *SAMPLE-NAMED-SECTIONS* :INSERT-IF-NOT-FOUND NIL))
(DEFTEST FIND-NAMED-SECTION (SECTION-NAME (FIND-SAMPLE-SECTION "bar")) "bar")
(DEFTEST FIND-SECTION-BY-PREFIX (SECTION-NAME (FIND-SAMPLE-SECTION "q..."))
         "qux")
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
         (LET ((*NAMED-SECTIONS* *SAMPLE-NAMED-SECTIONS*))
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
(DEFTEST EOF-P (EOF-P (READ-FROM-STRING "" NIL *EOF*)) T)
(DEFTEST EOF-TYPE (TYPEP (READ-FROM-STRING "" NIL *EOF*) 'EOF) T)
(DEFTEST (TOKEN-DELIMITER-P 1) (NOT (TOKEN-DELIMITER-P #\ )) NIL)
(DEFTEST (TOKEN-DELIMITER-P 2) (NOT (TOKEN-DELIMITER-P #\))) NIL)
(DEFTEST (READ-MAYBE-NOTHING 1)
         (WITH-INPUT-FROM-STRING (S "123") (READ-MAYBE-NOTHING S)) (123))
(DEFTEST (READ-MAYBE-NOTHING 2)
         (WITH-INPUT-FROM-STRING (S "#|x|#") (READ-MAYBE-NOTHING S)) NIL)
(DEFTEST (READ-MAYBE-NOTHING-PRESERVING-WHITESPACE)
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
(DEFTEST READ-WITH-ECHO
         (WITH-INPUT-FROM-STRING (STREAM ":foo :bar")
           (READ-WITH-ECHO (STREAM OBJECT CHARS)
             (VALUES OBJECT CHARS)))
         :FOO ":foo ")
(DEFTEST READ-WITH-ECHO-TO-EOF
         (WITH-INPUT-FROM-STRING (STREAM ":foo")
           (READ-WITH-ECHO (STREAM OBJECT CHARS)
             (VALUES OBJECT CHARS)))
         :FOO ":foo")
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
          (STRING
           &OPTIONAL (EOF-ERROR-P T) (EOF-VALUE NIL)
           &KEY (PRESERVE-WHITESPACE NIL)
           &AUX (STRING-STREAM (GENSYM)) (CHARPOS-STREAM (GENSYM)))
  `(WITH-OPEN-STREAM (,STRING-STREAM (MAKE-STRING-INPUT-STREAM ,STRING))
     (WITH-CHARPOS-INPUT-STREAM (,CHARPOS-STREAM ,STRING-STREAM)
       (IF ,PRESERVE-WHITESPACE
           (READ-PRESERVING-WHITESPACE ,CHARPOS-STREAM ,EOF-ERROR-P ,EOF-VALUE)
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
                   (EVAL (TANGLE (READ-FORM-FROM-STRING "`#(,a)")))
                   (EVAL (TANGLE (READ-FORM-FROM-STRING "`#(,@a)")))))
         #(:A) #((1 2 3)) #(1 2 3))
(DEFTEST READ-FUNCTION
         (LET ((MARKER (READ-FORM-FROM-STRING "#'identity")))
           (VALUES (QUOTED-FORM MARKER) (MARKER-VALUE MARKER)))
         IDENTITY #'IDENTITY)
(DEFTEST READ-SIMPLE-VECTOR
         (MARKER-VALUE (READ-FORM-FROM-STRING "#5(:a :b :c)"))
         #(:A :B :C :C :C))
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
         (LET ((MARKER (READ-FORM-FROM-STRING "#2A((1 2 3) (4 5 6))")))
           (EQUALP (MARKER-VALUE MARKER) #2A((1 2 3) (4 5 6))))
         T)
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
                (CONDITIONAL (MARKER-VALUE (READ-FORM-FROM-STRING "#-a 1"))))
           (VALUES (READ-TIME-CONDITIONAL-PLUSP CONDITIONAL)
                   (READ-TIME-CONDITIONAL-TEST CONDITIONAL)
                   (READ-TIME-CONDITIONAL-FORM CONDITIONAL)))
         NIL :A "1")
(DEFTEST (READ-TIME-CONDITIONAL 2)
         (LET ((*FEATURES* '(:A)) (*EVALUATING* T))
           (VALUES (MARKER-VALUE (READ-FORM-FROM-STRING "#+a 1"))
                   (MARKER-VALUE (READ-FORM-FROM-STRING "#-b 2"))
                   (MARKER-BOUNDP (READ-FORM-FROM-STRING "#-a 1"))
                   (MARKER-BOUNDP (READ-FORM-FROM-STRING "#+b 2"))))
         1 2 NIL NIL)
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
         (LET ((*NAMED-SECTIONS* *SAMPLE-NAMED-SECTIONS*))
           (WITH-MODE :LISP
             (SECTION-NAME (READ-FROM-STRING "@<foo@>"))))
         "foo")
(DEFTEST SECTION-NAME-DEFINITION-ERROR
         (LET ((*NAMED-SECTIONS* *SAMPLE-NAMED-SECTIONS*))
           (SECTION-NAME
            (HANDLER-BIND ((SECTION-NAME-DEFINITION-ERROR
                            (LAMBDA (CONDITION)
                              (DECLARE (IGNORE CONDITION))
                              (INVOKE-RESTART 'USE-SECTION))))
              (WITH-MODE :LISP
                (READ-FROM-STRING "@<foo@>=")))))
         "foo")
(DEFTEST SECTION-NAME-USE-ERROR
         (LET ((*NAMED-SECTIONS* *SAMPLE-NAMED-SECTIONS*))
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
(DEFTEST MAYBE-PUSH
         (LET ((LIST 'NIL))
           (MAYBE-PUSH 'A LIST)
           (MAYBE-PUSH NIL LIST)
           (MAYBE-PUSH "" LIST)
           (MAYBE-PUSH 'B LIST)
           LIST)
         (B A))
(DEFTEST (TANGLE-1 1) (TANGLE-1 (READ-FORM-FROM-STRING ":a")) :A NIL)
(DEFTEST (TANGLE-1 2) (TANGLE-1 (READ-FORM-FROM-STRING "(:a :b :c)"))
         (:A :B :C) T)
(DEFTEST (TANGLE-1 3)
         (LET ((*NAMED-SECTIONS* *SAMPLE-NAMED-SECTIONS*))
           (EQL (TANGLE-1 (READ-FORM-FROM-STRING "@<foo@>"))
                (FIND-SAMPLE-SECTION "foo")))
         T)
(DEFTEST TANGLE
         (LET ((*NAMED-SECTIONS* *SAMPLE-NAMED-SECTIONS*))
           (TANGLE (READ-FORM-FROM-STRING (FORMAT NIL "(:a @<foo@>~% :b)"))))
         (:A :FOO :B) T)
(DEFTEST (TESTS-FILE-PATHNAME 1)
         (EQUAL
          (TESTS-FILE-PATHNAME (MAKE-PATHNAME :NAME "FOO" :CASE :COMMON) "LISP"
                               :TESTS-FILE
                               (MAKE-PATHNAME :NAME "BAR" :CASE :COMMON))
          (MAKE-PATHNAME :NAME "BAR" :TYPE "LISP" :CASE :COMMON))
         T)
(DEFTEST (TESTS-FILE-PATHNAME 2)
         (EQUAL
          (TESTS-FILE-PATHNAME (MAKE-PATHNAME :NAME "FOO" :CASE :COMMON) "TEX")
          (MAKE-PATHNAME :NAME "FOO-TESTS" :TYPE "TEX" :CASE :COMMON))
         T)
(DEFTEST (TESTS-FILE-PATHNAME 3)
         (TESTS-FILE-PATHNAME (MAKE-PATHNAME :NAME "FOO" :CASE :COMMON) "LISP"
                              :TESTS-FILE NIL)
         NIL)
(DEFTEST PRINT-ESCAPED
         (WITH-OUTPUT-TO-STRING (S) (PRINT-ESCAPED S "foo#{bar}*baz"))
         "foo\\#$\\{$bar$\\}$*baz")
(DEFTEST (WALK-FUNCTION-NAME 1)
         (EQUAL (WALK-FUNCTION-NAME (MAKE-INSTANCE 'WALKER) 'FOO NIL) 'FOO) T)
(DEFTEST (WALK-FUNCTION-NAME 2)
         (EQUAL (WALK-FUNCTION-NAME (MAKE-INSTANCE 'WALKER) '(SETF FOO) NIL)
                '(SETF FOO))
         T)
(DEFTEST (WALK-FUNCTION-NAME 3)
         (LET ((ERROR-HANDLED NIL))
           (HANDLER-BIND ((INVALID-FUNCTION-NAME
                           (LAMBDA (CONDITION)
                             (SETQ ERROR-HANDLED T)
                             (CONTINUE CONDITION))))
             (VALUES
              (EQUAL
               (WALK-FUNCTION-NAME (MAKE-INSTANCE 'WALKER) '(FOO BAR) NIL)
               '(FOO BAR))
              ERROR-HANDLED)))
         T T)
(DEFTEST (WALK-FUNCTION 1)
         (TREE-EQUAL (WALK-FORM (MAKE-INSTANCE 'WALKER) '#'FOO NIL) '#'FOO) T)
(DEFTEST (WALK-FUNCTION 2)
         (TREE-EQUAL (WALK-FORM (MAKE-INSTANCE 'WALKER) '#'(SETF FOO) NIL)
                     '#'(SETF FOO))
         T)
(DEFTEST (WALK-FUNCTION 3)
         (TREE-EQUAL (WALK-FORM (MAKE-INSTANCE 'WALKER) '#'(LAMBDA (X) X) NIL)
                     '#'(LAMBDA (X) X))
         T)
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
(DEFCLASS TEST-WALKER (WALKER) NIL)
(DEFINE-SPECIAL-FORM-WALKER CHECK-BINDING
    ((WALKER TEST-WALKER) FORM ENV)
  (FLET ((CHECK-BINDING (NAME NAMESPACE ENV TYPE)
           (ASSERT
            (EQL
             (ECASE NAMESPACE
               (:FUNCTION (FUNCTION-INFORMATION NAME ENV))
               (:VARIABLE (VARIABLE-INFORMATION NAME ENV)))
             TYPE)
            (NAME NAMESPACE ENV TYPE) "~@(~A~) binding of ~A not of type ~A."
            NAMESPACE NAME TYPE)))
    (DESTRUCTURING-BIND
        (SYMBOLS NAMESPACE TYPE)
        (CDR FORM)
      (LOOP WITH SYMBOLS = (ENSURE-LIST SYMBOLS)
            FOR SYMBOL IN SYMBOLS
            DO (CHECK-BINDING SYMBOL NAMESPACE ENV TYPE))
      (IF (LISTP SYMBOLS)
          (WALK-LIST WALKER SYMBOLS ENV)
          (WALK-FORM WALKER SYMBOLS ENV)))))
(DEFMACRO DEFINE-WALK-BINDING-TEST (NAME FORM WALKED-FORM)
  `(DEFTEST ,NAME
            (TREE-EQUAL (WALK-FORM (MAKE-INSTANCE 'TEST-WALKER) ',FORM)
                        ',WALKED-FORM)
            T))
(DEFINE-WALK-BINDING-TEST WALK-ORDINARY-LAMBDA-LIST
 (LAMBDA
     (X Y
      &OPTIONAL
      (O
       (+ (CHECK-BINDING O :VARIABLE NIL) (CHECK-BINDING X :VARIABLE :SPECIAL)
          (CHECK-BINDING Y :VARIABLE :LEXICAL)))
      &KEY ((SECRET K) 1 K-S-P) (K2 (CHECK-BINDING K-S-P :VARIABLE :LEXICAL))
      K3
      &REST ARGS
      &AUX W
      (Z
       (IF K-S-P
           O
           X)))
   (DECLARE (SPECIAL X))
   (CHECK-BINDING X :VARIABLE :SPECIAL)
   (CHECK-BINDING (Y Z O K K-S-P K2 K3 ARGS W Z) :VARIABLE :LEXICAL)
   (CHECK-BINDING SECRET :VARIABLE NIL))
 (LAMBDA
     (X Y
      &OPTIONAL (O (+ O X Y))
      &KEY ((SECRET K) 1 K-S-P) (K2 K-S-P) K3
      &REST ARGS
      &AUX W
      (Z
       (IF K-S-P
           O
           X)))
   (DECLARE (SPECIAL X))
   X
   (Y Z O K K-S-P K2 K3 ARGS W Z)
   SECRET))
(DEFINE-WALK-BINDING-TEST WALK-MACRO-LAMBDA-LIST
 (LAMBDA
     (&WHOLE W (X Y)
      &OPTIONAL ((O) (+ X Y))
      &KEY ((:K (K1 K2)) (2 3) K-S-P) &ENVIRONMENT ENV . BODY)
   (CHECK-BINDING (W X Y O K1 K2 K-S-P ENV BODY) :VARIABLE :LEXICAL))
 (LAMBDA
     (&WHOLE W (X Y)
      &OPTIONAL ((O) (+ X Y))
      &KEY ((:K (K1 K2)) (2 3) K-S-P) &ENVIRONMENT ENV
      &REST BODY)
   (W X Y O K1 K2 K-S-P ENV BODY)))
(DEFINE-WALK-BINDING-TEST WALK-LET
 (LET ((X 1) (Y (CHECK-BINDING X :VARIABLE NIL)))
   (DECLARE (SPECIAL X))
   (CHECK-BINDING X :VARIABLE :SPECIAL)
   (CHECK-BINDING Y :VARIABLE :LEXICAL))
 (LET ((X 1) (Y X))
   (DECLARE (SPECIAL X))
   X
   Y))
(DEFINE-WALK-BINDING-TEST WALK-FLET
 (FLET ((FOO (X)
          (CHECK-BINDING X :VARIABLE :LEXICAL))
        (BAR (Y)
          Y))
   (DECLARE (SPECIAL X))
   (CHECK-BINDING X :VARIABLE :SPECIAL)
   (CHECK-BINDING FOO :FUNCTION :FUNCTION))
 (FLET ((FOO (X)
          X)
        (BAR (Y)
          Y))
   (DECLARE (SPECIAL X))
   X
   FOO))
(DEFINE-WALK-BINDING-TEST WALK-MACROLET
 (MACROLET ((FOO (X)
              `,(CHECK-BINDING X :VARIABLE :LEXICAL))
            (BAR (Y)
              `,Y))
   (CHECK-BINDING FOO :FUNCTION :MACRO)
   (FOO :FOO))
 (MACROLET ((FOO (X)
              X)
            (BAR (Y)
              Y))
   FOO
   :FOO))
(DEFINE-WALK-BINDING-TEST WALK-SYMBOL-MACROLET
 (SYMBOL-MACROLET ((FOO :FOO) (BAR :BAR))
   (CHECK-BINDING (FOO BAR) :VARIABLE :SYMBOL-MACRO))
 (SYMBOL-MACROLET ((FOO :FOO) (BAR :BAR))
   (:FOO :BAR)))
(DEFINE-WALK-BINDING-TEST WALK-LET*
 (LET* ((X 1) (Y (CHECK-BINDING X :VARIABLE :SPECIAL)))
   (DECLARE (SPECIAL X))
   (CHECK-BINDING Y :VARIABLE :LEXICAL))
 (LET* ((X 1) (Y X))
   (DECLARE (SPECIAL X))
   Y))
(DEFINE-WALK-BINDING-TEST WALK-LABELS
 (LABELS ((FOO (X)
            (CHECK-BINDING X :VARIABLE :LEXICAL))
          (BAR (Y)
            (CHECK-BINDING FOO :FUNCTION :FUNCTION)))
   (DECLARE (SPECIAL X))
   (CHECK-BINDING X :VARIABLE :SPECIAL)
   (CHECK-BINDING FOO :FUNCTION :FUNCTION))
 (LABELS ((FOO (X)
            X)
          (BAR (Y)
            FOO))
   (DECLARE (SPECIAL X))
   X
   FOO))
(DEFINE-WALK-BINDING-TEST WALK-LOCALLY
 (LET ((Y T))
   (CHECK-BINDING Y :VARIABLE :LEXICAL)
   (LOCALLY (DECLARE (SPECIAL Y)) (CHECK-BINDING Y :VARIABLE :SPECIAL)))
 (LET ((Y T))
   Y
   (LOCALLY (DECLARE (SPECIAL Y)) Y)))
(DEFCLASS TRACING-WALKER (WALKER) NIL)
(DEFMETHOD WALK-ATOMIC-FORM :BEFORE
           ((WALKER TRACING-WALKER) CONTEXT FORM ENV &KEY)
  (FORMAT T "; walking atomic form ~S (~S)~@[ (~(~A~) variable)~]~%" FORM
          CONTEXT (AND (SYMBOLP FORM) (VARIABLE-INFORMATION FORM ENV))))
(DEFMETHOD WALK-COMPOUND-FORM :BEFORE
           ((WALKER TRACING-WALKER) OPERATOR FORM ENV)
  (DECLARE (IGNORE OPERATOR ENV))
  (FORMAT T "~<; ~@;walking compound form ~W~:>~%" (LIST FORM)))
(DEFTEST INDEX-PACKAGE
         (LET ((*INDEX-PACKAGES* NIL))
           (INDEX-PACKAGE "KEYWORD")
           (VALUES (INTERESTING-SYMBOL-P NIL)
                   (NOT (NULL (INTERESTING-SYMBOL-P :FOO)))))
         NIL T)
(INDEX-PACKAGE "CLWEB")
(DEFTEST HEADING-NAME (HEADING-NAME (MAKE-HEADING "foo" (MAKE-HEADING "bar")))
         "foo bar")
(DEFTEST HEADING-NAME-CHARACTER (HEADING-NAME #\A) "a")
(DEFTEST HEADING-NAME-STRING (HEADING-NAME "\\foo") "foo")
(DEFTEST HEADING-NAME-SYMBOL
         (VALUES (HEADING-NAME :FOO) (HEADING-NAME '|\\foo|)) "foo" "\\foo")
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
                 (JOIN-STRINGS '(:FOO :BAR :BAZ) #\,))
         "foo" "foo bar" "FOO,BAR,BAZ")
(DEFCLASS DEAD-BEEF NIL NIL)
(DEFCLASS KOBE-BEEF (DEAD-BEEF) NIL)
(DEFGENERIC DESCRIBE-BEEF
    (BEEF)
  (:METHOD-COMBINATION JOIN-STRINGS ", ")
  (:METHOD ((BEEF DEAD-BEEF)) "steak")
  (:METHOD :PREFIX ((BEEF DEAD-BEEF)) (LIST "big" "fat" "juicy"))
  (:METHOD :SUFFIX ((BEEF DEAD-BEEF)) "yum!")
  (:METHOD :PREFIX ((BEEF KOBE-BEEF)) "delicious")
  (:METHOD ((BEEF KOBE-BEEF)) "Kobe")
  (:METHOD :SUFFIX ((BEEF KOBE-BEEF)) "from Japan"))
(DEFTEST JOIN-STRINGS-METHOD-COMBINATION
         (VALUES (DESCRIBE-BEEF (MAKE-INSTANCE 'DEAD-BEEF))
                 (DESCRIBE-BEEF (MAKE-INSTANCE 'KOBE-BEEF)))
         "big, fat, juicy, steak, yum!"
         "delicious, big, fat, juicy, Kobe, steak, yum!, from Japan")
(DEFTEST FUNCTION-HEADING-NAME
         (VALUES (HEADING-NAME (MAKE-TYPE-HEADING 'FUNCTION))
                 (HEADING-NAME (MAKE-TYPE-HEADING 'FUNCTION :LOCAL T))
                 (HEADING-NAME
                  (MAKE-TYPE-HEADING 'FUNCTION :GENERIC T :LOCAL NIL))
                 (HEADING-NAME (MAKE-TYPE-HEADING 'FUNCTION :SETF T))
                 (HEADING-NAME (MAKE-TYPE-HEADING 'FUNCTION :SETF T :LOCAL T)))
         "function" "local function" "generic function" "setf function"
         "local setf function")
(DEFTEST VARIABLE-HEADING-NAME
         (VALUES (HEADING-NAME (MAKE-TYPE-HEADING 'VARIABLE))
                 (HEADING-NAME (MAKE-TYPE-HEADING 'VARIABLE :SPECIAL T))
                 (HEADING-NAME (MAKE-TYPE-HEADING 'VARIABLE :CONSTANT T)))
         "variable" "special variable" "constant variable")
(DEFTEST MACRO-HEADING-NAME
         (VALUES (HEADING-NAME (MAKE-TYPE-HEADING 'MACRO))
                 (HEADING-NAME (MAKE-TYPE-HEADING 'SYMBOL-MACRO))
                 (HEADING-NAME (MAKE-TYPE-HEADING 'SYMBOL-MACRO :LOCAL T)))
         "macro" "symbol macro" "local symbol macro")
(DEFTEST CLASS-HEADING-NAME
         (VALUES (HEADING-NAME (MAKE-TYPE-HEADING 'CLASS))
                 (HEADING-NAME (MAKE-TYPE-HEADING 'CONDITION-CLASS)))
         "class" "condition class")
(DEFTEST METHOD-HEADING-NAME
         (VALUES (HEADING-NAME (MAKE-TYPE-HEADING 'METHOD))
                 (HEADING-NAME
                  (MAKE-TYPE-HEADING 'METHOD :QUALIFIERS
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
         (LET ((INDEX (MAKE-INDEX))
               (HEADING 'FOO)
               (*SECTIONS* (MAKE-ARRAY 3 :FILL-POINTER 0)))
           (ADD-INDEX-ENTRY INDEX HEADING (MAKE-INSTANCE 'SECTION))
           (ADD-INDEX-ENTRY INDEX HEADING (MAKE-INSTANCE 'SECTION))
           (ADD-INDEX-ENTRY INDEX HEADING (MAKE-INSTANCE 'SECTION))
           (SORT
            (MAPCAR #'SECTION-NUMBER
                    (MAPCAR #'LOCATION (FIND-INDEX-ENTRIES INDEX HEADING)))
            #'<))
         (0 1 2))
(DEFTEST (ADD-INDEX-ENTRY 2)
         (LET* ((INDEX (MAKE-INDEX))
                (HEADING 'FOO)
                (*SECTIONS* (MAKE-ARRAY 1 :FILL-POINTER 0))
                (SECTION (MAKE-INSTANCE 'SECTION)))
           (ADD-INDEX-ENTRY INDEX HEADING SECTION)
           (ADD-INDEX-ENTRY INDEX HEADING SECTION :DEF T)
           (LOCATOR-DEFINITION-P (FIRST (FIND-INDEX-ENTRIES INDEX HEADING))))
         T)
(DEFTEST (SYMBOL-PROVENANCE 1)
         (LET ((*INDEX-PACKAGES* (LIST (FIND-PACKAGE "KEYWORD"))))
           (SYMBOL-PROVENANCE (SUBSTITUTE-SYMBOLS :FOO 1)))
         :FOO 1)
(DEFTEST (SYMBOL-PROVENANCE 2) (SYMBOL-PROVENANCE :FOO) :FOO)
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
(DEFMACRO DEFINE-INDEXING-TEST (NAME SECTIONS &REST EXPECTED-ENTRIES)
  `(DEFTEST (INDEX ,NAME)
            (WITH-TEMPORARY-SECTIONS ,SECTIONS
             (LET ((TANGLED-CODE
                    (TANGLE (UNNAMED-SECTION-CODE-PARTS *SECTIONS*)))
                   (MANGLED-CODE (TANGLE-CODE-FOR-INDEXING *SECTIONS*))
                   (WALKER (MAKE-INSTANCE 'INDEXING-WALKER)))
               (LOOP WITH *INDEX-LEXICAL-VARIABLES* = NIL
                     FOR FORM IN TANGLED-CODE
                     AND MANGLED-FORM IN MANGLED-CODE AS WALKED-FORM = (WALK-FORM
                                                                        WALKER
                                                                        MANGLED-FORM)
                     DO (ASSERT (TREE-EQUAL WALKED-FORM FORM)
                                (WALKED-FORM MANGLED-FORM FORM)))
               (TREE-EQUAL (ALL-INDEX-ENTRIES (WALKER-INDEX WALKER))
                           ',EXPECTED-ENTRIES :TEST #'EQUAL)))
            T))
(DEFINE-INDEXING-TEST ATOM ((:SECTION :CODE (*SECTIONS*)))
 ("*sections* special variable" (0)))
(DEFINE-INDEXING-TEST FUNCALL
 ((:SECTION :CODE ((MAPAPPEND 'IDENTITY '(1 2 3))))) ("mapappend function" (0)))
(DEFINE-INDEXING-TEST FUNCTION-NAME
 ((:SECTION :CODE ((FLET ((FOO (X) X)))))
  (:SECTION :CODE ((FLET (((SETF FOO) (Y X) Y))))))
 ("foo local function" ((:DEF 0))) ("foo local setf function" ((:DEF 1))))
(DEFINE-INDEXING-TEST DEFUN ((:SECTION :CODE ((DEFUN FOO (X) X))))
 ("foo function" ((:DEF 0))))
(DEFINE-INDEXING-TEST DEFMACRO
 ((:SECTION :CODE ((DEFMACRO FOO (&BODY BODY) (MAPAPPEND 'IDENTITY BODY)))))
 ("foo macro" ((:DEF 0))) ("mapappend function" (0)))
(DEFINE-INDEXING-TEST DEFVAR
 ((:SECTION :CODE ((DEFVAR A T))) (:SECTION :CODE ((DEFPARAMETER B T)))
  (:SECTION :CODE ((DEFCONSTANT C T))))
 ("a special variable" ((:DEF 0))) ("b special variable" ((:DEF 1)))
 ("c constant variable" ((:DEF 2))))
(DEFTEST INDEXING-WALK-DECLARATION-SPECIFIERS
         (EQUAL
          (WALK-DECLARATION-SPECIFIERS (MAKE-INSTANCE 'INDEXING-WALKER)
                                       '((TYPE FOO X) (SPECIAL X Y) (IGNORE Z)
                                         (OPTIMIZE (SPEED 3) (SAFETY 0)))
                                       NIL)
          '((SPECIAL X Y) (OPTIMIZE (SPEED 3) (SAFETY 0))))
         T)
(DEFINE-INDEXING-TEST DEFGENERIC
 ((:SECTION :CODE
   ((DEFGENERIC FOO
        (X Y)
      (:DOCUMENTATION "foo")
      (:METHOD-COMBINATION PROGN)
      (:METHOD PROGN ((X T) Y) X)
      (:METHOD :AROUND (X (Y (EQL 'T))) Y)))))
 ("foo around method" ((:DEF 0))) ("foo generic function" ((:DEF 0)))
 ("foo progn method" ((:DEF 0))))
(DEFINE-INDEXING-TEST DEFMETHOD
 ((:SECTION :CODE ((DEFMETHOD ADD (X Y) (+ X Y))))
  (:SECTION :CODE ((DEFMETHOD ADD :BEFORE (X Y)))))
 ("add before method" ((:DEF 1))) ("add generic function" ((:DEF 0))))
(DEFINE-INDEXING-TEST DEFCLASS
 ((:SECTION :CODE ((DEFCLASS FOO NIL ((A :READER FOO-A1 :READER FOO-A2)))))
  (:SECTION :CODE
   ((DEFINE-CONDITION BAR
        NIL
        ((B :ACCESSOR FOO-B))))))
 ("bar condition class" ((:DEF 1))) ("foo class" ((:DEF 0)))
 ("foo-a1 generic function" ((:DEF 0))) ("foo-a2 generic function" ((:DEF 0)))
 ("foo-b generic function" ((:DEF 1))) ("foo-b primary setf method" ((:DEF 1))))
(DEFINE-INDEXING-TEST DEFINE-METHOD-COMBINATION
 ((:SECTION :CODE ((DEFINE-METHOD-COMBINATION FOO :OPERATOR BAR)))
  (:SECTION :CODE
   ((DEFGENERIC FOO
        NIL
      (:METHOD-COMBINATION FOO)))))
 ("foo generic function" ((:DEF 1))) ("foo method combination" (1 (:DEF 0))))
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
                (C (MAKE-MACRO-CHAR-HEADING #\c))
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
 ((:SECTION :CODE ((SET-MACRO-CHARACTER #\! #'READ-BANG)))
  (:SECTION :CODE ((SET-DISPATCH-MACRO-CHARACTER #\@ #\! #'READ-AT-BANG))))
 ("!" ((:DEF 0))) ("@ !" ((:DEF 1))))