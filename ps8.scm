#|
Rachel Rotteveel
6.905 Problem Set 7
May 5, 2017
|#

(cd "~/6.905_Pset8/propagator/")
(load "load")
(cd "~/6.905_Pset8")
(load "load")
(initialize-scheduler) ; initializes propagator system

(define-cell john-earnings)
(tell! john-earnings (make-interval 20 27) 'Harry-estimate)

(content john-earnings)]
#|
#(tms (#(value=#[interval 20 27],
	       premises=(harry-estimate),
	       informants=(user))))
|#

(tell! john-earnings (make-interval 15 21) 'Mary-estimate)
(pp (content john-earnings))
#|
#(tms
  (#(value=#[interval 20 21],
   premises=(harry-estimate mary-estimate),
   informants=(user))
   #(value=#[interval 15 21],
   premises=(mary-estimate),
   informants=(user))
   #(value=#[interval 20 27],
   premises=(harry-estimate),
   informants=(user))))
|#

;; best estimate based on both sources of information
(inquire john-earnings) 
#|
#(value=#[interval 20 21],
   premises=(harry-estimate mary-estimate),
   informants=(user))
|#

(tell! john-earnings (make-interval 25 30) 'bank-estimate)
;;(contradiction (mary-estimate harry-estimate bank-estimate))

(content john-earnings)
#|
#(tms (#(value=#[contradictory-interval 25 21],
   premises=(mary-estimate harry-estimate bank-estimate),
   informants=(user)) #(value=#[interval 25 30],
   premises=(bank-estimate),
   informants=(user)) #(value=#[interval 20 21],
   premises=(harry-estimate mary-estimate),
   informants=(user)) #(value=#[interval 15 21],
   premises=(mary-estimate),
   informants=(user)) #(value=#[interval 20 27],
   premises=(harry-estimate),
   informants=(user))))
|#

(inquire john-earnings)
#|
(contradiction (mary-estimate harry-estimate bank-estimate))
;Value: #(value=#[contradictory-interval 25 21],
   premises=(mary-estimate harry-estimate bank-estimate),
   informants=(user))
|#

(retract! 'Harry-estimate)

(inquire john-earnings)
#|
#(value=#[contradictory-interval 25 21],
   premises=(mary-estimate bank-estimate),
   informants=(user))
|#

(assert! 'Harry-estimate) ;; contradiction did not depend on Harry

(inquire john-earnings) ;; system now knows cont did not depend on Harry
#|
#(value=#[contradictory-interval 25 21],
   premises=(mary-estimate bank-estimate),
   informants=(user))
|#

(retract! 'Mary-estimate)

(inquire john-earnings)
#|
#(value=#[interval 25 27],
   premises=(harry-estimate bank-estimate),
   informants=(user))
|#

#|
First, we will define a compound propagator that takes a value cell,
an interval, and a boolean output cell. It tells the boolean output
cell to be true only if the contents of the value cell is within the
range specified by the range.
|#
(define-propagator (p:in-range? value interval bool)
  (p:and (e:<= (e:interval-low interval) value)
	 (e:<= value (e:interval-high interval))
	 bool))

;;; estimate is the cell to give a symbolic property. Interval is the
;;; range for which the property will be true. property-name is the
;;; symbol used to access the symbolic property cell (with eq-get)
;;; from the estimate cell.
(define (add-interval-property estimate interval property-name)
  ;; Is there already such a property on the estimate?
  (let ((status-cell (eq-get estimate property-name))) ;Already defined?
    (if status-cell
	;; Property already exists, get the range cell.
	(let ((range (eq-get estimate (symbol property-name ':range))))
	  (if (not range)
	      (error "Interval property has no range"
		     (name estimate) property-name))
	  (p:== interval range)
	  'range-updated)
	;; New definition: Create internal cells to hold the status of
	;; the symbolic property and its defining range (initialized
	;; to the given interval).
	(let-cells (status-cell range)
		   ;; Initialize the range cell.
		   (p:== interval range)
		   ;; Make the status and the range properties of the estimate.
		   (eq-put! estimate (symbol property-name ':range) range)
		   (eq-put! estimate property-name status-cell)
		   ;; If the cell content is within the interval
		   ;; then propagate #t to the status-cell.
		   (p:in-range? estimate range status-cell)
		   ;; If the status is true then propagate the content of the
		   ;; interval-call to the estimate.
		   (p:switch status-cell range estimate)
		   'property-added))))

(add-interval-property john-earnings (make-interval 0 20) 'loan-eligible)

(tell! (eq-get john-earnings 'loan-eligible) #t 'mit-financial)
;; (contradiction (bank-estimate harry-estimate mit-financial))

(for-each retract! '(harry-estimate bank-estimate))

(inquire john-earnings)
#|
#(value=#[interval 0 20],
   premises=(mit-financial),
   informants=((switch:p status-cell range)))
|#

(retract! 'mit-financial)

(inquire john-earnings)
;; #(*the-nothing*)

(inquire (eq-get john-earnings 'loan-eligible))
;; #(*the-nothing*)

(assert! 'Mary-estimate)

(inquire john-earnings)
#|
#(value=#[interval 15 21],
   premises=(mary-estimate),
   informants=(user))
|#

(inquire (eq-get john-earnings 'loan-eligible))
;; #(*the-nothing*)

(tell! john-earnings (make-interval 5 18) 'Debby-estimate)
(inquire john-earnings)
#|
#(value=#[interval 15 18],
   premises=(mary-estimate debby-estimate),
   informants=(user))
|#

(inquire (eq-get john-earnings 'loan-eligible))
#|
#(value=#t,
   premises=(debby-estimate mary-estimate),
   informants=((and:p cell19 cell17)))
|#

(define ((c:bins named-ranges) numeric-interval)
  (for-each
   (lambda (named-range)
     (add-interval-property numeric-interval
			    (cadr named-range)
			    (car named-range)))
   named-ranges))

(define-cell foo)

((c:bins (named-ranges 'gjs
		       '(low ,(make-interval 3 6))
		       '(medium ,(make-interval 5 8))
		       '(high ,(make-interval 7 9))))
 foo)
#|
The intervals will depend on the GJS premise. If GJS is retracted,
the intervals will become unknown, but the named cells will remain,
and new intervals can be placed in them.
|#

(draw:show-graph)

;;;;;;;;;;;;;;;;;;;
;;; Problem 8.1 ;;;
;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;
;;; Problem 8.2 ;;;
;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;
;;; Problem 8.3 ;;;
;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;
;;; Problem 8.4 ;;;
;;;;;;;;;;;;;;;;;;;
