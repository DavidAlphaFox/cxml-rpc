(cl:in-package #:cxml-rpc)

;;; client conditions:

(define-condition cxml-rpc-condition (error) ())

(define-condition network-error (cxml-rpc-condition) ())

(define-condition http-error (network-error)
  ((status-code :initarg :status-code :accessor status-code-of)
   (reason :initarg :reason :accessor reason-of)
   (headers :initarg :headers :accessor headers-of))
  (:report (lambda (c s)
             (format s "Got HTTP code ~A (expected 200), reason ~S"
                     (status-code-of c) (reason-of c)))))

(define-condition cxml-rpc-fault (cxml-rpc-condition)
  ((fault-code :initarg :fault-code :accessor fault-code-of)
   (fault-phrase :initarg :fault-phrase :accessor fault-phrase-of))
  (:report (lambda (c s)
             (format s "Got fault code ~A from server: ~A"
                     (fault-code-of c) (fault-phrase-of c)))))

(define-condition bad-response-structure (cxml-rpc-condition)
  ((element :initarg :element :accessor faulty-element)
   (expected :initarg :expected :accessor expected-element))
  (:report (lambda (c s)
             (format s "Bad XML-RPC response structure, got element ~S, ~
                        expected ~S" (faulty-element c) (expected-element c)))))

(define-condition bad-type-specifier (bad-response-structure)
  ((type-alist :initarg :type-alist :accessor type-alist))
  (:report (lambda (c s)
             (format s "Bad XML-RPC type specifier. Got ~S, expected ~
                        one of ~{~A~^, ~}" (faulty-element c)
                        (mapcar #'car (type-alist c))))))

(define-condition malformed-value-content (cxml-rpc-condition)
  ((type :initarg :type :accessor type-of-malformed-content)
   (content :initarg :content :accessor malformed-content))
  (:report (lambda (c s)
             (format s "Malformed ~a type content ~S."
                     (type-of-malformed-content c) (malformed-content c)))))

;;; server conditions:

(define-condition method-not-found (error)
  ((name :initarg :name :accessor name-of)
   (tag :initarg :tag :accessor tag-of))
  (:report (lambda (c s)
             (format s "Method ~S not found using tag ~S"
                     (name-of c) (tag-of c)))))

(define-condition method-arg-type-mismatch (error)
  ((position :initarg :position :accessor position-of)
   (expected :initarg :expected :accessor expected-arg)
   (got :initarg :got :accessor got-arg))
  (:report (lambda (c s)
             (format s "Parameter type mismatch at arg ~A: Expected ~A, got ~A"
                     (position-of c) (expected-arg c) (got-arg c)))))

(define-condition method-arg-count-mismatch (error)
  ((expected-min :initarg :expected-min :accessor minimum)
   (expected-max :initarg :expected-max :accessor maximum)
   (got :initarg :got :accessor got-args))
  (:report (lambda (c s)
             (format s "Argument count mismatch: Expected ~:[~A~*~;~A to ~A~], ~
                        got ~A"
                     (/= (minimum c) (maximum c)) (minimum c) (maximum c)
                     (got-args c)))))