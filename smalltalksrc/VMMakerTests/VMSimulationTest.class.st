Class {
	#name : #VMSimulationTest,
	#superclass : #TestCase,
	#category : #'VMMakerTests-Simulation'
}

{ #category : #tests }
VMSimulationTest >> testSetUpJITSimulationReadsImage [

	| options c |
	"Smoke test, check that the VM can open the image file"
	self timeLimit: 60 seconds.
	
	InterpreterStackPages initialize.
	options := {
	    #ObjectMemory -> #Spur64BitCoMemoryManager.
	    #ISA -> #aarch64.
	    #BytesPerWord -> 8.
	    #MULTIPLEBYTECODESETS -> true.
	    #bytecodeTableInitializer -> #initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid.
	} asDictionary.

	c := CogVMSimulator newWithOptions: options.
	c
		openOn: Smalltalk imagePath
		extraMemory: 100000.
]

{ #category : #tests }
VMSimulationTest >> testSetUpNonJITSimulationReadsImage [

	| options c |
	"Smoke test, check that the VM can open the image file"
	self timeLimit: 60 seconds.
	
	InterpreterStackPages initialize.
	options := {
	    #ObjectMemory -> #Spur64BitMemoryManager.
	    #BytesPerWord -> 8.
	    #MULTIPLEBYTECODESETS -> true.
	    #bytecodeTableInitializer -> #initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid.
	} asDictionary.

	c := StackInterpreterSimulator newWithOptions: options.
	c
		openOn: Smalltalk imagePath
		extraMemory: 100000.
]
