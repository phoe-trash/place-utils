(cl:defpackage #:place-utils_tests
  (:use #:cl #:place-utils #:parachute))

(cl:in-package #:place-utils_tests)

(define-test "featured examples"
  (is equal '((nil (0 10 2) 10)
              "(0 1 2)")
      (let* ((my-list (list 0 1 2))
             (my-other-list my-list)
             (output (make-array 0 :element-type 'character :fill-pointer t :adjustable t)))
        (with-output-to-string (*standard-output* output)
          (list (with-resolved-places ((second (second (princ my-list))))
                  (setf my-list nil second 8)
                  (incf second 2)
                  (list my-list my-other-list second))
                output))))
  (flet ((double (number)
           (* number 2)))
    (is equal '(4 nil)
        (let ((a 2) (b 8))
          (updatef (values a b) #'double)
          (list a b)))
    (is equal '(6 -8)
        (let ((a 2) (b 8))
          (updatef a #'1+
                   a #'double
                   b #'-)
          (list a b)))
    (is equalp '(#(1 4) 3)
        (let ((a (vector 1 2))
              (printcount 0))
          (flet ((fakeprint (value)
                   (incf printcount)
                   value))
            (updatef (aref (fakeprint a) (fakeprint 1))
                     (fakeprint #'double))
            (list a printcount)))))
  (is equal '(25 100 (25 100))
      (flet ((bulkf-transfer (quantity source destination)
               (values (- source quantity)
                       (+ destination quantity))))
        (macrolet ((transferf (quantity source destination)
                     `(bulkf #'bulkf-transfer
                             :pass ,quantity
                             :access ,source ,destination)))
          (let ((account-amounts (list 35 90)))
            (multiple-value-call #'list
              (transferf 10
                         (first account-amounts)
                         (second account-amounts))
              account-amounts)))))
  (is equal '(0 0 (nil 0 nil))
      (flet ((bulkf-init (value number-of-places)
               (values-list (make-list number-of-places
                                       :initial-element value))))
        (macrolet ((initf (value &rest places)
                     `(bulkf #'bulkf-init
                             :pass ,value ,(length places)
                             :write ,@places)))
          (let (a b (c (make-list 3 :initial-element nil)))
            (initf 0 a b (second c))
            (list a b c)))))
  (flet ((bulkf-spread (spread-function sum-function
                                        &rest place-values)
           (values-list
            (let ((number-of-places (length place-values)))
              (make-list number-of-places
                         :initial-element
                         (funcall spread-function
                                  (apply sum-function place-values)
                                  number-of-places))))))
    (macrolet ((spreadf (spread-function sum-function &rest places)
                 `(bulkf #'bulkf-spread :pass ,spread-function ,sum-function
                         :access ,@places)))
      (is equal '(11 (11 11 20))
          (let ((a 5) (b (list 10 18 20)))
            (spreadf #'/ #'+ a (first b) (second b))
            (list a b)))
      (is equal '(512 (512 512 512))
          (let ((a 2) (b (list 2 4 8)))
            (spreadf #'* #'* a (first b) (second b) (third b))
            (list a b)))))
  (is equal '((1 6 16) 1 6 (10 16))
      (flet ((bulkf-map (function &rest place-values)
               (values-list (mapcar function place-values))))
        (macrolet ((mapf (function &rest places)
                     `(bulkf #'bulkf-map :pass ,function :access ,@places)))
          (let ((a 0) (b 5) (c (list 10 15)))
            (list (multiple-value-list (mapf #'1+ a b (second c)))
                  a b c)))))
  (is equal '((:INITIAL-ASSETS (:PAINTINGS :COLLECTION) 20000 NIL :RANDOM-STUFF 400)
              NIL
              0
              (:NOTHING-VALUABLE NIL 0))
      (flet ((bulkf-steal (sum-function steal-function
                                        initial-assets &rest target-assets)
               (let (stolen leftovers)
                 (mapc (lambda (assets)
                         (multiple-value-bind (steal leftover)
                             (funcall steal-function assets)
                           (push steal stolen)
                           (push leftover leftovers)))
                       target-assets)
                 (values-list
                  (cons (apply sum-function
                               (cons initial-assets (nreverse stolen)))
                        (nreverse leftovers))))))
        (macrolet ((stealf (sum-function steal-function hideout &rest targets)
                     `(bulkf #'bulkf-steal :pass ,sum-function ,steal-function
                             :access ,hideout ,@targets)))
          (let ((cave :initial-assets)
                (museum '(:paintings :collection))
                (house 20000)
                (triplex (list :nothing-valuable :random-stuff 400)))
            (stealf #'list
                    (lambda (assets)
                      (if (eq assets :nothing-valuable)
                          (values nil assets)
                          (values assets (if (numberp assets) 0 nil))))
                    cave museum house (first triplex) (second triplex) (third triplex))
            (list cave museum house triplex)))))
  (flet ((test (initial-value expected-result)
           (is equal expected-result
               (let ((cache initial-value)
                     (output (make-array 0 :element-type 'character :fill-pointer t :adjustable t)))
                 (with-output-to-string (*standard-output* output)
                   (incf (cachef nil cache 0 :test #'numberp) (princ (+ 5 2)))
                   (list cache output))))))
    (test "cached-string" '(7 "7"))
    (test 20 '(27 "7")))
  (is equal '((:full :computed-value) "(:EMPTY :PLACEHOLDER)")
      (let ((values (list :empty :placeholder))
            (output (make-array 0 :element-type 'character :fill-pointer t :adjustable t)))
        (with-output-to-string (*standard-output* output)
          (cachef (first values) (second (prin1 values))
                  :computed-value
                  :test (lambda (marker)
                          (ecase marker
                            (:full t)
                            (:empty nil)))
                  :new-cachedp :full)
          (list values output))))
  (is equal '(5 7)
      (let ((a 5))
        (list (incf (oldf a) 2)
              a)))
  (is equal '(5 10)
      (let ((a 5))
        (list (setf (oldf a) 10)
              a)))
  (is equal '((1 2 3) (0 1 2 3))
      (let ((list '(1 2 3)))
        (list (push 0 (oldf list))
              list))))
