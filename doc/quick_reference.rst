:Document Author: Luke Domanski, CSIRO, IM&T, Scientific Computing
:Document Format: This document was written in reStructuredText_. There a
                  numerous converters and generators for `exporting from
                  reStructuredText`_ to pretty document formats.

.. _reStructuredText: http://docutils.sourceforge.net/rst.html
.. _exporting from reStructuredText: http://docutils.sourceforge.net/docs/user/links.html#export

======================================
Job Parallel Framework Quick Reference
======================================

.. contents::

Loading the parallel platform
=============================
Before calling **ANY** parallel framework routines, load the framework::

    IDL> load_par_framework


Generating parallel jobs
========================

Generating a standard parallel job
----------------------------------
Let:

- ``task_list`` be an existing array of task structures ``t``
- ``my_worker`` be a task function that accepts a ``t`` structure, and returns a
  ``t_post`` structure

Generate a parallel job that processes all tasks in ``task_list`` using
``my_worker`` across 8 parallel workers::

    IDL> generate_parallel_job, task_params=task_list, $
                                job_dir=”./parallel_job_1”, $
                                work_func=”my_worker”, $
                                n_workers=8

Using pre and post processing task functions
--------------------------------------------
Let:

- ``pre_task_list`` be an existing array of task structures ``t_pre``
- ``my_preprocessor`` be a task function that accepts a ``t_pre`` structure, and
  returns a ``t`` structure
- ``my_worker`` be a task function that accepts a ``t`` structure, and returns a
  ``t_post`` structure
- ``my_postprocessor`` be a task function that accepts a ``t_post`` structure,
  and returns a ``t_res`` structure


Generate a parallel job that runs all tasks in ``pre_task_list`` through the
ordered phases ``my_preprocessor``, ``my_worker``, and ``my_postprocessor``
across 8 parallel workers::

    IDL> generate_parallel_job, task_params=pre_task_list, $
                                job_dir=”./parallel_job_2”, $
                                preprocess_fun="my_preprocessor", $
                                work_func=”my_worker”, $
                                postprocess_fun="my_postprocessor", $
                                n_workers=8

Using subdivision
-----------------
Let:

- ``big_task_list`` be an existing array of task structures ``t_big``
- ``my_subdivider`` be a task function that accepts a ``t_big`` structure, and
  returns *N* ``t_part`` structures
- ``my_part_worker`` be a task function that accepts a ``t_part`` structure, and
  returns a ``t_part_res`` structure
- ``my_collator`` be a task function that accepts *N* ``t_part_res`` structures,
  and returns a ``t_res`` structure


Generate a parallel job that:

1. subdivides all tasks in ``big_task_list`` into *N=4* subtasks using ``my_subdivider``
2. processes each subtask using ``my_part_worker``
3. combines groups of *N=4* subtask results using ``my_collator``

across a **MAXIMUM** of 16 parallel workers::


    IDL> generate_parallel_job, task_params=bug_task_list, $
                                job_dir=”./parallel_job_3”, $
                                preprocess_fun="my_subdivider", $
                                work_func=”my_part_worker”, $
                                postprocess_fun="my_collator", $
                                n_workers=16,
                                task_subdivision=4

Changing job generator
======================

Get generator information
-------------------------
Discover what generator plugins are available::

    IDL> plugins=discover_generator_plugins()

Print information about the first plugin listed::

    IDL> print, "Plugin Name: ", plugins[0,0]
    Plugin Name: IDL Parallel Framework PBS job array+Linux job generator
    IDL> print, "Plugin Description: ", plugins[2,0]
    Plugin Description:
    IDL Parallel Framework job generator for Linux systems running the Portable
    Batch System (PBS). It utilises PBS job arrays, and supports Torque PBS.
    IDL> print, "Plugin Ident: ", plugins[3,0]
    Plugin Ident: pbs_job_array_job_generator

Load a generator
----------------
Load the first generator listed by ``plugins=discover_generator_plugins()``::

    IDL> load_generator_plugin, plugin_ident=plugins[3,0]

All subsequent calls to ``generate_parallel_job`` use this generator until
another is loaded.


