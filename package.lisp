(in-package #:cl-user)

(defpackage #:place-utils
  (:use #:cl)
  (:export #:setf-expanderlet
	   #:with-resolved-places
	   
	   #:updatef
	   #:bulkf
	   #:setfnew
	   #:funcallf
	   #:applyf

	   ;#:proxyf
	   ;#:call-next-customizer
	   #:cachef
	   #:oldf
	   #:readf
	   #:tracef))
