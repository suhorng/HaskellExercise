#lang racket

(define to-s
  (λ (d)
    (~a #:max-width 45 #:limit-prefix? #t #:limit-marker "..." d)))


(define make-eval
  (λ ()
    (define evl (current-eval))
    (define new-evl
      (λ (expr)
        (printf "EVAL ")
        (cond
          [(compiled-module-expression? expr)
           (printf "<compiled module ~a>\n" (module-compiled-name expr))]
          [(or (compiled-expression? expr)
               (and (syntax? expr) (compiled-expression? (syntax-e expr))))
           (printf "<compiled expression>\n")]
          [else (printf "~a\n" expr)])
        (evl expr)))
    new-evl))


(define make-resolver
  (λ ()
    (define resolver (current-module-name-resolver))
    (define new-resolver
      (case-lambda
        [(resolved-path ns)
         (printf "REGISTER ~a ~a\n" (to-s resolved-path) ns)
         (resolver resolved-path ns)]
        [(path relative-resolved-path stx perform-load?)
         (printf "QUERY/LOAD ~a ~a ~a ~a\n"
                 path (to-s relative-resolved-path)
                 (to-s stx) perform-load?)
         (resolver path relative-resolved-path stx perform-load?)]))
    new-resolver))


(define make-compile
  (λ ()
    (define comp (current-compile))
    (define new-comp
      (λ (expr immediate-eval?)
        (unless (compiled-expression? expr)
          (printf "========= COMPILING ~a =========\n"
                  (to-s (current-module-declare-name)))
          (pretty-print
           (if (syntax? expr) (syntax->datum expr) expr))
          (printf "=============================\n"))
        (comp expr immediate-eval?)))
    new-comp))


(define make-load/use-compiled
  (λ ()
    (define ld/uc (current-load/use-compiled))
    (define new-ld/uc
      (λ (path names)
        (printf "USE-COMPILED? ~a\n" (to-s (path->string path)))
        (ld/uc path names)))
    new-ld/uc))


(define make-load
  (λ ()
    (define ld (current-load))
    (define new-ld
      (λ (path names)
        (printf "LOADING ~a\n" (to-s (path->string path)))
        (ld path names)))
    new-ld))


(module+ main
  (require "dynrun.rkt")

  (parameterize ([current-eval (make-eval)]
                 [current-module-name-resolver (make-resolver)]
                 [current-compile (make-compile)]
                 [current-load/use-compiled (make-load/use-compiled)]
                 [current-load (make-load)]
                 #;[use-compiled-file-paths '()])
    #;(run-dynamic-require)
    (define m (read-module))
    (eval-module m ''hello)))