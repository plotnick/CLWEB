;;;; TANGLED OUTPUT FROM WEB "clweb.lw".  DO NOT EDIT.
(DEFPACKAGE "COMMON-LISP-WEB" (:NICKNAMES "CLWEB") (:USE "COMMON-LISP")
            (:EXPORT "TANGLE-FILE" "LOAD-WEB" "WEAVE"))
(IN-PACKAGE "CLWEB")
(DEFPARAMETER *SECTION-NUMBER* 0)
(DEFCLASS SECTION NIL
          ((NUMBER :READER SECTION-NUMBER :INITARG :NUMBER :INITFORM
            (INCF *SECTION-NUMBER*))
           (COMMENTARY :ACCESSOR SECTION-COMMENTARY :INITARG :COMMENTARY)
           (NAME :ACCESSOR SECTION-NAME :INITARG :NAME)
           (CODE :ACCESSOR SECTION-CODE :INITARG :CODE)
           (USED-BY :ACCESSOR USED-BY :INITARG :USED-BY))
          (:DEFAULT-INITARGS :COMMENTARY NIL :NAME NIL :CODE NIL :USED-BY NIL))
(DEFCLASS LIMBO-SECTION (SECTION) NIL)
(DEFCLASS STARRED-SECTION (SECTION) NIL)
(DEFCLASS BINARY-SEARCH-TREE NIL
          ((KEY :ACCESSOR NODE-KEY :INITARG :KEY)
           (VALUE :ACCESSOR NODE-VALUE :INITARG :VALUE)
           (LEFT-CHILD :ACCESSOR LEFT-CHILD :INITARG :LEFT)
           (RIGHT-CHILD :ACCESSOR RIGHT-CHILD :INITARG :RIGHT))
          (:DEFAULT-INITARGS :KEY NIL :VALUE NIL :LEFT NIL :RIGHT NIL))
(DEFGENERIC FIND-OR-INSERT (ITEM ROOT &KEY PREDICATE TEST INSERT-IF-NOT-FOUND))
(DEFMETHOD FIND-OR-INSERT
           (ITEM (ROOT BINARY-SEARCH-TREE) &KEY (PREDICATE #'<) (TEST #'EQL)
            (INSERT-IF-NOT-FOUND T))
           (FLET ((LESSP (ITEM NODE)
                    (FUNCALL PREDICATE ITEM (NODE-KEY NODE)))
                  (SAMEP (ITEM NODE)
                    (FUNCALL TEST ITEM (NODE-KEY NODE))))
             (DO ((PARENT NIL NODE)
                  (NODE ROOT
                        (IF (LESSP ITEM NODE) (LEFT-CHILD NODE)
                            (RIGHT-CHILD NODE))))
                 ((OR (NULL NODE) (SAMEP ITEM NODE))
                  (IF NODE (VALUES NODE T)
                      (IF INSERT-IF-NOT-FOUND
                          (LET ((NODE
                                 (MAKE-INSTANCE (CLASS-OF ROOT) :KEY ITEM)))
                            (WHEN PARENT
                              (IF (LESSP ITEM PARENT)
                                  (SETF (LEFT-CHILD PARENT) NODE)
                                  (SETF (RIGHT-CHILD PARENT) NODE)))
                            (VALUES NODE NIL))
                          (VALUES NIL NIL)))))))
(DEFCLASS NAMED-SECTION (BINARY-SEARCH-TREE)
          ((KEY :ACCESSOR SECTION-NAME :INITARG :NAME)
           (VALUE :ACCESSOR SECTION-CODE :INITARG :CODE)))
(DEFMETHOD FIND-OR-INSERT
           (ITEM (ROOT NAMED-SECTION) &KEY (PREDICATE #'SECTION-NAME-LESSP)
            (TEST #'SECTION-NAME-EQUAL) (INSERT-IF-NOT-FOUND T))
           (MULTIPLE-VALUE-BIND
               (NODE PRESENT-P)
               (CALL-NEXT-METHOD ITEM ROOT :PREDICATE PREDICATE :TEST TEST
                :INSERT-IF-NOT-FOUND INSERT-IF-NOT-FOUND)
             (IF PRESENT-P
                 (OR
                  (DOLIST (CHILD (LIST (LEFT-CHILD NODE) (RIGHT-CHILD NODE)))
                    (WHEN CHILD
                      (MULTIPLE-VALUE-BIND
                          (ALT PRESENT-P)
                          (CALL-NEXT-METHOD ITEM CHILD :PREDICATE PREDICATE
                           :TEST TEST :INSERT-IF-NOT-FOUND NIL)
                        (WHEN PRESENT-P
                          (RESTART-CASE
                           (ERROR
                            "~<Ambiguous prefix <~A>: matches both <~A> and <~A>~:@>"
                            (LIST ITEM (NODE-KEY NODE) (NODE-KEY ALT)))
                           (USE-FIRST-MATCH NIL :REPORT "Use the first match."
                            (RETURN (VALUES NODE T)))
                           (USE-ALT-MATCH NIL :REPORT
                            "Use the alternate match."
                            (RETURN (VALUES ALT T))))))))
                  (VALUES NODE T))
                 (VALUES NODE NIL))))
(DEFPARAMETER *NAMED-SECTIONS* NIL)
(DEFUN FIND-SECTION (NAME)
  (IF (NULL *NAMED-SECTIONS*)
      (VALUES (SETQ *NAMED-SECTIONS* (MAKE-INSTANCE 'NAMED-SECTION :NAME NAME))
              NIL)
      (MULTIPLE-VALUE-BIND
          (SECTION PRESENT-P)
          (FIND-OR-INSERT NAME *NAMED-SECTIONS*)
        (WHEN PRESENT-P (SETF (SECTION-NAME SECTION) NAME))
        (VALUES SECTION PRESENT-P))))
(DEFUN DEFINE-SECTION (NAME FORMS)
  (MULTIPLE-VALUE-BIND
      (SECTION PRESENT-P)
      (FIND-SECTION NAME)
    (DECLARE (IGNORE PRESENT-P))
    (SETF (SECTION-CODE SECTION) (APPEND (SECTION-CODE SECTION) FORMS))
    SECTION))
(DEFPARAMETER *WHITESPACE*
  (COERCE '(#\  #\Tab #\Newline #\Newline #\Page #\Return) 'SIMPLE-STRING))
(DEFUN SQUEEZE (STRING)
  (FLET ((WHITESPACE-P (CHAR)
           (FIND CHAR *WHITESPACE* :TEST #'CHAR=)))
    (COERCE
     (LOOP WITH SQUEEZING = NIL FOR CHAR ACROSS
           (STRING-TRIM *WHITESPACE* STRING) IF (NOT SQUEEZING) IF
           (WHITESPACE-P CHAR) DO (SETQ SQUEEZING T) AND COLLECT #\  ELSE
           COLLECT CHAR ELSE UNLESS (WHITESPACE-P CHAR) DO (SETQ SQUEEZING NIL)
           AND COLLECT CHAR)
     'SIMPLE-STRING)))
(DEFUN SECTION-NAME-PREFIX-P (NAME)
  (LET ((LEN (LENGTH NAME)))
    (IF (STRING= (SUBSEQ NAME (MAX (- LEN 3) 0) LEN) "...")
        (VALUES T (- LEN 3)) (VALUES NIL LEN))))
(DEFUN SECTION-NAME-EQUAL (NAME1 NAME2)
  (MULTIPLE-VALUE-BIND
      (PREFIX-1-P LEN1)
      (SECTION-NAME-PREFIX-P NAME1)
    (MULTIPLE-VALUE-BIND
        (PREFIX-2-P LEN2)
        (SECTION-NAME-PREFIX-P NAME2)
      (LET ((END (MIN LEN1 LEN2)))
        (IF (OR PREFIX-1-P PREFIX-2-P)
            (STRING-EQUAL NAME1 NAME2 :END1 END :END2 END)
            (STRING-EQUAL NAME1 NAME2))))))
(DEFUN SECTION-NAME-LESSP (NAME1 NAME2)
  (MULTIPLE-VALUE-BIND
      (PREFIX-1-P LEN1)
      (SECTION-NAME-PREFIX-P NAME1)
    (DECLARE (IGNORE PREFIX-1-P))
    (MULTIPLE-VALUE-BIND
        (PREFIX-2-P LEN2)
        (SECTION-NAME-PREFIX-P NAME2)
      (DECLARE (IGNORE PREFIX-2-P))
      (STRING-LESSP NAME1 NAME2 :END1 LEN1 :END2 LEN2))))
(DEFMETHOD (SETF SECTION-NAME) :AROUND (NEW-NAME (SECTION NAMED-SECTION))
           (MULTIPLE-VALUE-BIND
               (NEW-PREFIX-P NEW-LEN)
               (SECTION-NAME-PREFIX-P NEW-NAME)
             (MULTIPLE-VALUE-BIND
                 (OLD-PREFIX-P OLD-LEN)
                 (SECTION-NAME-PREFIX-P (SECTION-NAME SECTION))
               (IF
                (OR (AND OLD-PREFIX-P (NOT NEW-PREFIX-P))
                    (AND OLD-PREFIX-P NEW-PREFIX-P (< NEW-LEN OLD-LEN)))
                (CALL-NEXT-METHOD) NEW-NAME))))
(DEFUN TANGLE-1 (FORM)
  (COND ((ATOM FORM) (VALUES FORM NIL))
        ((TYPEP (CAR FORM) 'NAMED-SECTION)
         (VALUES (APPEND (SECTION-CODE (CAR FORM)) (TANGLE-1 (CDR FORM))) T))
        (T
         (MULTIPLE-VALUE-BIND
             (A CAR-EXPANDED-P)
             (TANGLE-1 (CAR FORM))
           (MULTIPLE-VALUE-BIND
               (D CDR-EXPANDED-P)
               (TANGLE-1 (CDR FORM))
             (VALUES
              (IF (AND (EQL A (CAR FORM)) (EQL D (CDR FORM))) FORM (CONS A D))
              (OR CAR-EXPANDED-P CDR-EXPANDED-P)))))))
(DEFUN TANGLE (FORM)
  (LABELS ((EXPAND (FORM EXPANDED)
             (MULTIPLE-VALUE-BIND
                 (NEW-FORM NEWLY-EXPANDED-P)
                 (TANGLE-1 FORM)
               (IF NEWLY-EXPANDED-P (EXPAND NEW-FORM T)
                   (VALUES NEW-FORM EXPANDED)))))
    (EXPAND FORM NIL)))
(DEFUN UNNAMED-SECTION-CODE (STREAM)
  (LOOP FOR SECTION IN (READ-SECTIONS STREAM) IF (SECTION-NAME SECTION) DO
        (DEFINE-SECTION (SECTION-NAME SECTION) (SECTION-CODE SECTION)) ELSE
        APPEND (SECTION-CODE SECTION)))
(DEFUN LOAD-WEB-FROM-STREAM (STREAM VERBOSE PRINT)
  (WHEN VERBOSE (FORMAT T "~&; loading WEB from ~S~%" (PATHNAME STREAM)))
  (SETQ *SECTION-NUMBER* 0)
  (SETQ *NAMED-SECTIONS* NIL)
  (LET ((*READTABLE* *READTABLE*) (*PACKAGE* *PACKAGE*))
    (DOLIST (FORM (TANGLE (UNNAMED-SECTION-CODE STREAM)))
      (IF PRINT
          (LET ((RESULTS (MULTIPLE-VALUE-LIST (EVAL FORM))))
            (FORMAT T "~&; ~{~S~^, ~}~%" RESULTS))
          (EVAL FORM)))))
(DEFUN LOAD-WEB
       (FILESPEC
        &KEY (VERBOSE *LOAD-VERBOSE*) (PRINT *LOAD-PRINT*)
        (IF-DOES-NOT-EXIST T) (EXTERNAL-FORMAT :DEFAULT))
  (IF (STREAMP FILESPEC) (LOAD-WEB-FROM-STREAM FILESPEC VERBOSE PRINT)
      (WITH-OPEN-FILE
          (STREAM FILESPEC :DIRECTION :INPUT :EXTERNAL-FORMAT EXTERNAL-FORMAT
           :IF-DOES-NOT-EXIST (IF IF-DOES-NOT-EXIST :ERROR NIL))
        (LOAD-WEB-FROM-STREAM STREAM VERBOSE PRINT))))
(DEFUN TANGLE-FILE
       (INPUT-FILE
        &REST ARGS
        &KEY OUTPUT-FILE (VERBOSE *COMPILE-VERBOSE*) (PRINT *COMPILE-PRINT*)
        (EXTERNAL-FORMAT :DEFAULT) &ALLOW-OTHER-KEYS
        &AUX
        (LISP-FILE (MERGE-PATHNAMES (MAKE-PATHNAME :TYPE "lisp") INPUT-FILE)))
  (DECLARE (IGNORE OUTPUT-FILE PRINT))
  (WHEN VERBOSE (FORMAT T "~&; tangling WEB from ~S~%" INPUT-FILE))
  (SETQ *SECTION-NUMBER* 0)
  (SETQ *NAMED-SECTIONS* NIL)
  (WITH-OPEN-FILE
      (INPUT INPUT-FILE :DIRECTION :INPUT :EXTERNAL-FORMAT EXTERNAL-FORMAT)
    (WITH-OPEN-FILE
        (LISP LISP-FILE :DIRECTION :OUTPUT :IF-EXISTS :SUPERSEDE
         :EXTERNAL-FORMAT EXTERNAL-FORMAT)
      (FORMAT LISP ";;;; TANGLED OUTPUT FROM WEB ~S.  DO NOT EDIT." INPUT-FILE)
      (DOLIST (FORM (TANGLE (UNNAMED-SECTION-CODE INPUT)))
        (PPRINT FORM LISP))))
  (APPLY #'COMPILE-FILE LISP-FILE ARGS))
(DEFPARAMETER *MODES* '(:LIMBO :TEX :LISP :INNER-LISP :RESTRICTED))
(DEFTYPE MODE () `(MEMBER ,@*MODES*))
(DEFVAR *READTABLES*
  (LOOP FOR MODE IN *MODES* COLLECT (CONS MODE (COPY-READTABLE NIL))))
(DEFUN READTABLE-FOR-MODE (MODE)
  (DECLARE (TYPE MODE MODE))
  (CDR (ASSOC MODE *READTABLES*)))
(DEFMACRO WITH-MODE (MODE &BODY BODY)
  `(LET ((*READTABLE* (READTABLE-FOR-MODE ,MODE)))
     ,@BODY))
(DEFVAR *EOF* (MAKE-SYMBOL "EOF"))
(DEFUN EOF-P (CHAR) (EQ CHAR *EOF*))
(DEFUN SNARF-UNTIL-CONTROL-CHAR
       (STREAM
        &OPTIONAL RESTRICTED
        &AUX (CONTROL-CHARS (IF RESTRICTED '(#\@) '(#\@ #\|))))
  (WITH-OUTPUT-TO-STRING (STRING)
    (LOOP FOR CHAR = (PEEK-CHAR NIL STREAM NIL *EOF* NIL) UNTIL
          (OR (EOF-P CHAR) (MEMBER CHAR CONTROL-CHARS)) DO
          (WRITE-CHAR (READ-CHAR STREAM) STRING))))
(DEFUN READ-INNER-LISP (STREAM CHAR)
  (WITH-MODE :INNER-LISP (READ-DELIMITED-LIST CHAR STREAM T)))
(SET-MACRO-CHARACTER #\| #'READ-INNER-LISP NIL (READTABLE-FOR-MODE :TEX))
(SET-MACRO-CHARACTER #\| (GET-MACRO-CHARACTER #\) NIL) NIL
                     (READTABLE-FOR-MODE :INNER-LISP))
(DOLIST (MODE *MODES*)
  (IGNORE-ERRORS
   (MAKE-DISPATCH-MACRO-CHARACTER #\@ T (READTABLE-FOR-MODE MODE))))
(DEFUN GET-CONTROL-CODE (SUB-CHAR MODE)
  (GET-DISPATCH-MACRO-CHARACTER #\@ SUB-CHAR (READTABLE-FOR-MODE MODE)))
(DEFUN SET-CONTROL-CODE (SUB-CHAR FUNCTION &OPTIONAL (MODES *MODES*))
  (DOLIST (MODE MODES)
    (SET-DISPATCH-MACRO-CHARACTER #\@ SUB-CHAR FUNCTION
                                  (READTABLE-FOR-MODE MODE))))
(SET-CONTROL-CODE #\@
                  (LAMBDA (STREAM SUB-CHAR ARG)
                    (DECLARE (IGNORE STREAM ARG))
                    (STRING SUB-CHAR)))
(DEFUN START-SECTION-READER (STREAM SUB-CHAR ARG)
  (DECLARE (IGNORE STREAM ARG))
  (MAKE-INSTANCE (ECASE SUB-CHAR (#\  'SECTION) (#\* 'STARRED-SECTION))))
(DOLIST (SUB-CHAR '(#\  #\*))
  (SET-CONTROL-CODE SUB-CHAR #'START-SECTION-READER '(:LIMBO :TEX :LISP)))
(DEFSTRUCT (START-CODE (:CONSTRUCTOR MAKE-START-CODE (EVALP &OPTIONAL NAME)))
  EVALP
  NAME)
(DEFUN START-CODE-READER (STREAM SUB-CHAR ARG)
  (DECLARE (IGNORE STREAM ARG))
  (MAKE-START-CODE (ECASE SUB-CHAR ((#\L #\P) NIL) (#\E T))))
(DOLIST (SUB-CHAR '(#\l #\p #\e))
  (SET-CONTROL-CODE SUB-CHAR #'START-CODE-READER '(:TEX)))
(DEFVAR *END-CONTROL-TEXT* (MAKE-SYMBOL "@>"))
(SET-CONTROL-CODE #\> (CONSTANTLY *END-CONTROL-TEXT*) '(:RESTRICTED))
(DEFUN READ-CONTROL-TEXT (STREAM)
  (WITH-MODE :RESTRICTED
             (APPLY #'CONCATENATE 'STRING
                    (LOOP FOR TEXT = (SNARF-UNTIL-CONTROL-CHAR STREAM T) AS X =
                          (READ-PRESERVING-WHITESPACE STREAM T NIL T) COLLECT
                          TEXT UNTIL (EQ X *END-CONTROL-TEXT*) COLLECT X))))
(DEFUN MAKE-SECTION-NAME-READER (DEFINITION-ALLOWED-P)
  (LAMBDA (STREAM SUB-CHAR ARG)
    (DECLARE (IGNORE SUB-CHAR ARG))
    (LET* ((NAME (READ-CONTROL-TEXT STREAM))
           (DEFINITION-P (EQL (PEEK-CHAR NIL STREAM NIL NIL T) #\=)))
      (IF DEFINITION-P
          (IF DEFINITION-ALLOWED-P
              (PROGN (READ-CHAR STREAM) (MAKE-START-CODE NIL NAME))
              (RESTART-CASE
               (ERROR "Can't define a named section in Lisp mode: ~A" NAME)
               (USE-SECTION NIL :REPORT
                "Don't define the section, just use it." (FIND-SECTION NAME))))
          (IF DEFINITION-ALLOWED-P
              (RESTART-CASE
               (ERROR "Can't use a section name in TeX mode: ~A" NAME)
               (NAME-SECTION NIL :REPORT
                "Name the current section and start the code part."
                (MAKE-START-CODE NIL NAME))
               (CITE-SECTION NIL :REPORT
                "Assume the section is just being cited." (FIND-SECTION NAME)))
              (FIND-SECTION NAME))))))
(SET-CONTROL-CODE #\< (MAKE-SECTION-NAME-READER T) '(:TEX))
(SET-CONTROL-CODE #\< (MAKE-SECTION-NAME-READER NIL) '(:LISP :INNER-LISP))
(DEFUN READ-SECTIONS (STREAM)
  (FLET ((FINISH-SECTION (SECTION COMMENTARY CODE)
           (SETF (SECTION-COMMENTARY SECTION) (NREVERSE COMMENTARY))
           (SETF (SECTION-CODE SECTION) (NREVERSE CODE))
           SECTION))
    (PROG (FORM COMMENTARY CODE SECTION SECTIONS)
     LIMBO
      (SETQ SECTION (MAKE-INSTANCE 'LIMBO-SECTION))
      (WITH-MODE :LIMBO
                 (LOOP (PUSH (SNARF-UNTIL-CONTROL-CHAR STREAM T) COMMENTARY)
                       (SETQ FORM (READ STREAM NIL *EOF* NIL))
                       (COND ((EOF-P FORM) (GO EOF))
                             ((TYPEP FORM 'SECTION) (GO COMMENTARY))
                             (T (PUSH FORM COMMENTARY)))))
     COMMENTARY
      (PUSH (FINISH-SECTION SECTION COMMENTARY CODE) SECTIONS)
      (CHECK-TYPE FORM SECTION)
      (SETQ SECTION FORM COMMENTARY 'NIL CODE 'NIL)
      (WITH-MODE :TEX
                 (LOOP (PUSH (SNARF-UNTIL-CONTROL-CHAR STREAM) COMMENTARY)
                       (SETQ FORM (READ STREAM NIL *EOF* NIL))
                       (COND ((EOF-P FORM) (GO EOF))
                             ((TYPEP FORM 'SECTION) (GO COMMENTARY))
                             ((START-CODE-P FORM)
                              (SETF (SECTION-NAME SECTION)
                                      (START-CODE-NAME FORM))
                              (GO LISP))
                             (T (PUSH FORM COMMENTARY)))))
     LISP
      (WITH-MODE :LISP
                 (LET ((EVALP (START-CODE-EVALP FORM)))
                   (LOOP (SETQ FORM (READ STREAM NIL *EOF* NIL))
                         (COND ((EOF-P FORM) (GO EOF))
                               ((TYPEP FORM 'SECTION) (GO COMMENTARY))
                               ((START-CODE-P FORM)
                                (ERROR
                                 "Can't start a section with a code part"))
                               (T (WHEN EVALP (EVAL FORM))
                                (PUSH FORM CODE))))))
     EOF
      (PUSH (FINISH-SECTION SECTION COMMENTARY CODE) SECTIONS)
      (RETURN (NREVERSE SECTIONS)))))