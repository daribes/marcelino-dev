;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                     ;;;
;;;                     Carnegie Mellon University                      ;;;
;;;                  and Alan W Black and Kevin Lenzo                   ;;;
;;;                      Copyright (c) 1998-2000                        ;;;
;;;                        All Rights Reserved.                         ;;;
;;;                                                                     ;;;
;;; Permission is hereby granted, free of charge, to use and distribute ;;;
;;; this software and its documentation without restriction, including  ;;;
;;; without limitation the rights to use, copy, modify, merge, publish, ;;;
;;; distribute, sublicense, and/or sell copies of this work, and to     ;;;
;;; permit persons to whom this work is furnished to do so, subject to  ;;;
;;; the following conditions:                                           ;;;
;;;  1. The code must retain the above copyright notice, this list of   ;;;
;;;     conditions and the following disclaimer.                        ;;;
;;;  2. Any modifications must be clearly marked as such.               ;;;
;;;  3. Original authors' names are not deleted.                        ;;;
;;;  4. The authors' names are not used to endorse or promote products  ;;;
;;;     derived from this software without specific prior written       ;;;
;;;     permission.                                                     ;;;
;;;                                                                     ;;;
;;; CARNEGIE MELLON UNIVERSITY AND THE CONTRIBUTORS TO THIS WORK        ;;;
;;; DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING     ;;;
;;; ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT  ;;;
;;; SHALL CARNEGIE MELLON UNIVERSITY NOR THE CONTRIBUTORS BE LIABLE     ;;;
;;; FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES   ;;;
;;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN  ;;;
;;; AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,         ;;;
;;; ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF      ;;;
;;; THIS SOFTWARE.                                                      ;;;
;;;                                                                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                       ;;
;;;  A Scheme for a Spanish set of diphones                               ;;
;;;  Inspired by Steve Isard's diphone schemas from CSTR, University of   ;;
;;;  Edinburgh                                                            ;;
;;;                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; A diphone list for SAMPA

(set! vowels '(a i u e o a1 i1 u1 e1 o1 ax))
(set! stressedvowels '(a1 i1 u1 e1 o1))
(set! unstressedvowels '(a i u e o ax))
(set! strongvowels '(a e o a1 e1 o1))
(set! weakvowels '(i u))
(set! schwa '(ax))
(set! consonants '(p b B ch d D f g G k l ll m n ny r rr s t th x dh hh sh v z zh))
(set! stops-bdg '(b d g))
(set! approximants-BDG '(B D G))
(set! stops '(p b t d k g))
(set! fricatives '(f th s x))
(set! nasals '(n m ny))
(set! affricates '(ch))
(set! laterals '(l ll))
(set! onset-only '(rr ll ny ch g hh dh sh v z zh))
(set! onset-only+approximants-BDG '(rr ll ny ch hh dh v z zh sh B D G)) ;; g has been removed because it can appear in coda position, as in the word "blog"
(set! svibrant '(r))
(set! svibrant+approximants-BDG '(r B D G))
(set! liquids '(l r))
(set! englishconsonants '(dh hh sh v z zh))
(set! englishvoicedcons '(dh v z zh))
(set! englishvoicelesscons '(hh sh))
(set! englishconsonants+approximants-BDG '(dh hh sh v z zh B D G))
(set! englishvowel '(ax))
(set! silence '#)
(set! clusters1
      (append
       (apply
	append
	(mapcar (lambda (b) (mapcar (lambda (a) (list a b)) '(p b k g))) '(l r)))
       (mapcar (lambda (b) (list 's b)) '(l n m p t k f))
       (mapcar (lambda (b) (list 'f b)) '(l r))))

(set! cvc1-carrier '((# t a ) (a #)))  ;;carrier for consonant-vowel + vowel-consonant (stressed vowels)
(set! cvc2-carrier '((# t a1 ) (a #)))  ;;carrier for consonant-vowel + vowel-consonant (unstressed vowels)
(set! vc1-carrier '((# t a t) (a #)))  ;;carrier for vowel-consonant (stressed vowels)
(set! vc2-carrier '((# t a t) (a1 #)))  ;;carrier for vowel-consonant (unstressed vowels)
(set! cv1-carrier '((# t a ) (t a #)))  ;;carrier for consonant-vowel (stressed vowels)
(set! cv2-carrier '((# t a ) (t a1 #)))  ;;carrier for consonant-vowel (unstressed vowels)
(set! cc-carrier '((# t a ) (a1 t a #)))  ;;carrier for consonant-consonant
(set! vv0-carrier '((# t a t) (t a1 #)))  ;;vowel-vowel carrier for unstressed pairs (a-a)
(set! vv1-carrier '((# t a t) (t a #)))  ;;vowel-vowel carrier for stressed-unstressed pairs (a1-a)
(set! vv2-carrier '((# t a t) (t a #)))  ;;vowel-vowel carrier for unstressed-stressed pairs (a-a1)
(set! vv3-carrier '((# t a t) (t a #)))  ;;vowel-vowel carrier for stressed pairs (a1-a1)
(set! silv1-carrier '(() (t a #)))  ;;carrier for silence+vowel (stressed vowels)
(set! silv2-carrier '(() (t a1 #)))  ;;carrier for silence+vowel (unstressed vowels)
(set! silc-carrier '(() (a1 t a #)))  ;;carrier for silence+consonant
(set! vsil1-carrier '((# t a t ) ()))  ;;carrier for vowel+silence (stressed vowels)
(set! vsil2-carrier '((# t a1 t ) ()))  ;;carrier for vowel+silence (unstressed vowels)
(set! csil-carrier '((# t a t a1) ()))  ;;carrier for consonant+silence
(set! cc1-carrier '((# t a -) (a1 t a #))) ;;carrier for clusters (pr,pl,br,bl,kr,kl,gr,gl,fl,fr)
(set! LR1-carrier '((# t a - k) (t a #)))
(set! LR2-carrier '((# t a - k) (t a1 #)))

;;; These functions simply fill out the nonsense words
;;; from the carriers and vowel consonant definitions


;;; Carrier for consonant-vowel + vowel-consonant (stressed vowels)
(define (list-cvcs1)
  (apply
   append
   (mapcar
    (lambda (v)
      (mapcar
       (lambda (c)
	 (list
	  (list (string-append c "-" v) (string-append v "-" c))
	  (append (car cvc1-carrier) (list c v c) (car (cdr cvc1-carrier)))))
       (remove-list consonants stops-bdg)))
  stressedvowels)))

;;; Carrier for consonant-vowel + vowel-consonant (unstressed vowels)
(define (list-cvcs2)
  (apply
   append
   (mapcar
    (lambda (v)
      (mapcar
       (lambda (c)
	 (list
	  (list (string-append c "-" v) (string-append v "-" c))
	  (append (car cvc2-carrier) (list c v c) (car (cdr cvc2-carrier)))))
       (remove-list consonants stops-bdg)))
    unstressedvowels)))

;;; Carrier for vowel-consonant (stressed vowels)
(define (list-vcs1)
  (apply
   append
   (mapcar
    (lambda (v)
      (mapcar
       (lambda (c)
	 (list
	  (list (string-append v "-" c))
	  (append (car vc1-carrier) (list v c) (car (cdr vc1-carrier)))))
       (remove-list consonants stops-bdg)))
   stressedvowels)))

;;; Carrier for vowel-consonant (unstressed vowels)
(define (list-vcs2)
  (apply
   append
   (mapcar
    (lambda (v)
      (mapcar
       (lambda (c)
	 (list
	  (list (string-append v "-" c))
	  (append (car vc2-carrier) (list v c) (car (cdr vc2-carrier)))))
       (remove-list consonants stops-bdg)))
   unstressedvowels)))

;;; Carrier for consonant-vowel (stressed vowels)
(define (list-cvs1)
  (apply
   append
   (mapcar
    (lambda (c)
      (mapcar 
       (lambda (v) 
	 (list
	  (list (string-append c "-" v))
	  (append (car cv1-carrier) (list c v) (car (cdr cv1-carrier)))))
       stressedvowels))
    (remove-list consonants stops-bdg))))

;;; Carrier for consonant-vowel (unstressed vowels)
(define (list-cvs2)
  (apply
   append
   (mapcar
    (lambda (c)
      (mapcar 
       (lambda (v) 
	 (list
	  (list (string-append c "-" v))
	  (append (car cv2-carrier) (list c v) (car (cdr cv2-carrier)))))
       unstressedvowels))
    (remove-list consonants stops-bdg))))

;;; Carrier for vowel-vowel (unstressed-unstressed)
(define (list-vv0s)
  (apply
   append
   (mapcar
    (lambda (v1)
      (mapcar 
       (lambda (v2) 
	 (list
	  (list (string-append v1 "-" v2))
	  (append (car vv0-carrier) (list v1 v2) (car (cdr vv0-carrier)))))
       unstressedvowels))
    unstressedvowels)))

;;; Carrier for vowel-vowel (stressed-unstressed)
(define (list-vv1s)
  (apply
   append
   (mapcar
    (lambda (v1)
      (mapcar 
       (lambda (v2) 
	 (list
	  (list (string-append v1 "-" v2))
	  (append (car vv1-carrier) (list v1 v2) (car (cdr vv1-carrier)))))
       (remove-list unstressedvowels schwa)))
    stressedvowels)))

;;; Carrier for vowel-vowel (unstressed-stressed)
(define (list-vv2s)
  (apply
   append
   (mapcar
    (lambda (v1)
      (mapcar 
       (lambda (v2) 
	 (list
	  (list (string-append v1 "-" v2))
	  (append (car vv2-carrier) (list v1 v2) (car (cdr vv2-carrier)))))
       stressedvowels))
    (remove-list unstressedvowels schwa))))

;;; Carrier for vowel-vowel (stressed-stressed)
(define (list-vv3s)
  (apply
   append
   (mapcar
    (lambda (v1)
      (mapcar 
       (lambda (v2) 
	 (list
	  (list (string-append v1 "-" v2))
	  (append (car vv3-carrier) (list v1 '- v2) (car (cdr vv3-carrier)))))
       stressedvowels))
    stressedvowels)))

;;; Carrier for consonant-consonant
(define (list-ccs)
  (apply
   append
   (mapcar
    (lambda (c1)
      (mapcar 
       (lambda (c2) 
       (list
	(list (string-append c1 "-" c2))
	(append (car cc-carrier) (list c1 '- c2) (car (cdr cc-carrier)))))
       (remove-list consonants englishconsonants+approximants-BDG)))
    (remove-list consonants onset-only+approximants-BDG))))

;;; Carrier for consonant-consonant (exceptions 1a: voiced consonants)
(define (list-ccs1a)
  (apply
   append
   (mapcar
    (lambda (c1)
      (mapcar 
       (lambda (c2) 
       (list
	(list (string-append c1 "-" c2))
	(append (car cc-carrier) (list c1 '- c2) (car (cdr cc-carrier)))))
      '(z)))
    '(b d g l m n r))))

;;; Carrier for consonant-consonant (exceptions 1b: voiced consonants)
(define (list-ccs1b)
  (apply
   append
   (mapcar
    (lambda (c1)
      (mapcar 
       (lambda (c2) 
       (list
	(list (string-append c1 "-" c2))
	(append (car cc-carrier) (list c1 '- c2) (car (cdr cc-carrier)))))
      '(b d g l m n r)))
    '(z))))

;;; Carrier for consonant-consonant (exceptions 1c: voiced consonants)
(define (list-ccs1c)
  (apply
   append
   (mapcar
    (lambda (c1)
      (mapcar 
       (lambda (c2) 
       (list
	(list (string-append c1 "-" c2))
	(append (car cc-carrier) (list c1 '- c2) (car (cdr cc-carrier)))))
      '(v)))
    '(r z))))

;;; Carrier for consonant-consonant (exceptions 1d: voiced consonants)
(define (list-ccs1d)
  (apply
   append
   (mapcar
    (lambda (c1)
      (mapcar 
       (lambda (c2) 
       (list
	(list (string-append c1 "-" c2))
	(append (car cc-carrier) (list c1 '- c2) (car (cdr cc-carrier)))))
      '(r z)))
    '(v))))

;;; Carrier for consonant-consonant (exceptions 2a: voiceless consonants)
(define (list-ccs2a)
  (apply
   append
   (mapcar
    (lambda (c1)
      (mapcar 
       (lambda (c2) 
       (list
	(list (string-append c1 "-" c2))
	(append (car cc-carrier) (list c1 '- c2) (car (cdr cc-carrier)))))
      '(sh)))
    '(p f k t))))

;;; Carrier for consonant-consonant (exceptions 2b: voiceless consonants)
(define (list-ccs2b)
  (apply
   append
   (mapcar
    (lambda (c1)
      (mapcar 
       (lambda (c2) 
       (list
	(list (string-append c1 "-" c2))
	(append (car cc-carrier) (list c1 '- c2) (car (cdr cc-carrier)))))
      '(p f k t)))
    '(sh))))

;;; Carrier for silence+vowel (stressed vowels)
(define (list-silv1)
  (mapcar 
   (lambda (v) 
     (list
      (list (string-append silence "-" v))
      (append (car silv1-carrier) (list silence v) (car (cdr silv1-carrier)))))
   stressedvowels))

;;; Carrier for silence+vowel (unstressed vowels)
(define (list-silv2)
  (mapcar 
   (lambda (v) 
     (list
      (list (string-append silence "-" v))
      (append (car silv2-carrier) (list silence v) (car (cdr silv2-carrier)))))
   unstressedvowels))

;;; Carrier for silence-consonant
(define (list-silc)
  (mapcar 
   (lambda (c) 
     (list
      (list (string-append silence "-" c))
      (append (car silc-carrier) (list silence c) (car (cdr silc-carrier)))))
   (remove-list consonants approximants-BDG)))

;;; Carrier for consonant+silence
(define (list-csil)
  (mapcar 
   (lambda (c) 
     (list
      (list (string-append c "-" silence))
      (append (car csil-carrier) (list c silence) (car (cdr csil-carrier)))))
   (remove-list consonants '(rr ll ny hh dh zh B D G))))

;;; Carrier for vowel-silence (stressed vowels)
(define (list-vsil1)
  (mapcar 
   (lambda (v) 
     (list
      (list (string-append v "-" silence))
      (append (car vsil1-carrier) (list v silence) (car (cdr vsil1-carrier)))))
   stressedvowels))

;;; Carrier for vowel-silence (unstressed vowels)
(define (list-vsil2)
  (mapcar 
   (lambda (v) 
     (list
      (list (string-append v "-" silence))
      (append (car vsil2-carrier) (list v silence) (car (cdr vsil2-carrier)))))
   unstressedvowels))
  
;;; Carrier for consonant clusters (pr,pl,br,bl,kr,kl,gr,gl,fl,fr)
(define (list-ccclust1)
  (mapcar
   (lambda (c1c2)
     (list
      (list (string-append (car c1c2) "_-_" (car (cdr c1c2))))
      (append (car cc1-carrier) c1c2 (car (cdr cc1-carrier)))))
   clusters1))

;;; Carrier for consonant-vowel (stressed vowels)
(define (list-LR1)
  (apply
   append
   (mapcar
    (lambda (c)
      (mapcar 
       (lambda (v) 
	 (list
	  (list (string-append c "-" v))
	  (append (car LR1-carrier) (list c v) (car (cdr LR1-carrier)))))
       stressedvowels))
    '(l r))))

;;; Carrier for consonant-vowel (unstressed vowels)
(define (list-LR2)
  (apply
   append
   (mapcar
    (lambda (c)
      (mapcar 
       (lambda (v) 
	 (list
	  (list (string-append c "-" v))
	  (append (car LR2-carrier) (list c v) (car (cdr LR2-carrier)))))
       unstressedvowels))
    '(l r))))

(define (list-cvcs-appendix1)
  (apply
   append
   (mapcar
    (lambda (v)
      (mapcar
       (lambda (c)
	 (list
	  (list (string-append c "-" v) (string-append v "-" c))
	  (append (car cvc1-carrier) (list c v c) (car (cdr cvc1-carrier)))))
       stops-bdg))
  stressedvowels)))

(define (list-cvcs-appendix2)
  (apply
   append
   (mapcar
    (lambda (v)
      (mapcar
       (lambda (c)
	 (list
	  (list (string-append c "-" v) (string-append v "-" c))
	  (append (car cvc2-carrier) (list c v c) (car (cdr cvc2-carrier)))))
       stops-bdg))
  unstressedvowels)))

;;; End of individual generation functions

(define (diphone-gen-list)
  "(diphone-gen-list)
Returns a list of nonsense words as phone strings."
  (append
   (list-cvcs1) 
   (list-cvcs2)
 ;;  (list-vcs1)
 ;;  (list-vcs2) 
 ;;  (list-cvs2)  
 ;;  (list-cvs1) 
   (list-vv0s) 
   (list-vv1s)
   (list-vv2s)  
   (list-vv3s)
   (list-ccs)  
   (list-ccs1a)
   (list-ccs1b)
   (list-ccs1c)
   (list-ccs1d)
   (list-ccs2a)
   (list-ccs2b)
   (list-silv1)
   (list-silv2)
   (list-silc)
   (list-csil)
   (list-vsil1)
   (list-vsil2)
   (list-ccclust1)
   (list-LR1)
   (list-LR2)
   (list
    '(("#-#") (# t a t a # #)))
   (list-cvcs-appendix1)
   (list-cvcs-appendix2)
   (list
    '(("t_-_r") (# o1 t r o s #)))
   (list
    '(("d_-_r") (# m i m a1 d r e #)))
   ))

(define (Diphone_Prompt_Setup)
 "(Diphone_Prompt_Setup)
Called before synthesizing the prompt waveforms."
 (voice_el_diphone)  ;; Spanish male voice
 (set! FP_F0 90) 
 )

;; Because we're actually generating the prompts using the existing Spanish el_diphone voice,
;; we map the (both Spanish and English) phonemes that we introduced in our extended phone set
;; to alredy existing phonemes in the previously defined Spanish phone set.
(set! nhg2radio_map
      '((B b)
	(D d)
	(G g)
	(L l)
	(R r)
	(ax e)
	(dh d)
	(hh x)
	(sh s)
	(v b)
	(z s)
	(zh ll)))

(define (Diphone_Prompt_Word utt)
  "(Diphone_Prompt_Word utt)
Specify specific modifications of the utterance before synthesis
specific to this particular phone set."
  (mapcar
   (lambda (s)
     (let ((n (item.name s))
	   (newn (cdr (assoc_string (item.name s) nhg2radio_map))))
       (cond
	((cdr newn)  ;; its a dual one
	 (let ((newi (item.insert s (list (car (cdr newn))) 'after)))
	   (item.set_feat newi "end" (item.feat s "end"))
	   (item.set_feat s "end"
			  (/ (+ (item.feat s "segment_start")
				(item.feat s "end"))
			     2))
	   (item.set_name s (car newn))))
	(newn
	 (item.set_name s (car newn)))
	(t
	 ;; as is
	 ))))
   (utt.relation.items utt 'Segment))
  utt)

(provide 'es_schema)
