; docformat = 'rst'
;+
; A warper around the IDL Job Parallel Framework's `parallel_worker` procedure.
;
; It is used by the Framework as the entry point procedure to Parallel Worker
; processes, to avoid copying the entire `parallel_worker` source or binary to
; the parallel job directory.
;
; :Private_file:
;-
pro parfw_runner

    parallel_worker

end

