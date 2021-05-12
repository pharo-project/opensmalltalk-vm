Class {
	#name : #CSlangPrettyPrinter,
	#superclass : #CAbstractNodeVisitor,
	#instVars : [
		'stream',
		'level'
	],
	#category : #'Slang-AST'
}

{ #category : #accessing }
CSlangPrettyPrinter >> contents [
	
	^ stream contents
]

{ #category : #initialization }
CSlangPrettyPrinter >> initialize [

	super initialize.
	stream := '' writeStream.
	level := 0
]

{ #category : #generated }
CSlangPrettyPrinter >> visitArray: anArrayAcess [

	anArrayAcess array acceptVisitor: self.
	stream nextPut: $[.
	anArrayAcess index acceptVisitor: self.
	stream nextPut: $]
]

{ #category : #generated }
CSlangPrettyPrinter >> visitArrayDeclarator: anArrayDeclarator [

	anArrayDeclarator declarator acceptVisitor: self.
	stream nextPut: $[.
	anArrayDeclarator size ifNotNil: [ :size |
		stream nextPutAll: size asString ].
	stream nextPut: $]
]

{ #category : #generated }
CSlangPrettyPrinter >> visitArrow: aPointerAccess [

	aPointerAccess structurePointer acceptVisitor: self.
	stream nextPutAll: '->'.
	aPointerAccess member acceptVisitor: self
]

{ #category : #generated }
CSlangPrettyPrinter >> visitAssignment: anAssignment [

	anAssignment lvalue acceptVisitor: self.
	stream
		nextPutAll: ' ';
		nextPutAll: anAssignment operator;
		nextPutAll: ' '.


	anAssignment rvalue acceptVisitor: self
]

{ #category : #generated }
CSlangPrettyPrinter >> visitBinary: aBinary [
	| leftParenthesises rightParenthesises |
	
	leftParenthesises := (aBinary left isConstant or: [ aBinary left isIdentifier ]).
	rightParenthesises := (aBinary right isConstant or: [ aBinary right isIdentifier ]).
	
	leftParenthesises ifFalse: [ stream nextPutAll: '(' ].
	aBinary left acceptVisitor: self.
	leftParenthesises ifFalse: [ stream nextPutAll: ')' ].
	
	stream
		nextPutAll: ' ';
		nextPutAll: aBinary operator;
		nextPutAll: ' '.
		
	rightParenthesises ifFalse: [ stream nextPutAll: '(' ].
	aBinary right acceptVisitor: self.
	rightParenthesises ifFalse: [ stream nextPutAll: ')' ].
]

{ #category : #generated }
CSlangPrettyPrinter >> visitBreakStatement: aBreakStatement [

	stream nextPutAll: 'break'
]

{ #category : #generated }
CSlangPrettyPrinter >> visitCall: aCall [
	
	
	stream nextPutAll: (aCall identifier name).
	stream nextPutAll: '('.
	aCall arguments do: [ :arg | arg acceptVisitor: self ] separatedBy: [ stream nextPutAll: ', '].
	stream nextPutAll: ')'.
		
]

{ #category : #generated }
CSlangPrettyPrinter >> visitCastExpression: aCastExpression [

	stream nextPut: $(.
	aCastExpression type acceptVisitor: self.
	stream nextPut: $).
	stream nextPut: $(.
	aCastExpression expression acceptVisitor: self.
	stream nextPut: $)
]

{ #category : #generated }
CSlangPrettyPrinter >> visitComment: aComment [

	stream nextPutAll: '/* '.
	stream nextPutAll: aComment comment.
	stream nextPutAll: ' */'
]

{ #category : #generated }
CSlangPrettyPrinter >> visitCompoundStatement: aCompoundStatement [

	aCompoundStatement needsBrackets ifTrue: [ 
		stream
			tab: level;
			nextPutAll: '{'.

		level := level + 1.
		stream crtab: level ].

	aCompoundStatement declarations , aCompoundStatement statements
		do: [ :e | e acceptVisitor: self ]
		separatedBy: [ 
			aCompoundStatement needsSeparator ifTrue: [ 
				stream nextPut: $;.
				stream crtab: level ] ].

	aCompoundStatement needsBrackets ifTrue: [ 
		stream nextPut: $;.
		level := level - 1.
		stream
			crtab: level;
			nextPut: $}.
		aCompoundStatement needsCarriageReturn ifTrue: [ stream cr ] ]
]

{ #category : #generated }
CSlangPrettyPrinter >> visitConstant: aConstant [

	stream nextPutAll: aConstant value asString
]

{ #category : #generated }
CSlangPrettyPrinter >> visitDeclaration: aDeclaration [

	aDeclaration specifiers
		do: [ :e | 
			stream nextPutAll: e.
			stream space ].
	
	aDeclaration declarators
		do: [ :e | e acceptVisitor: self ]
		separatedBy: [ stream nextPutAll: ', ' ].
]

{ #category : #generated }
CSlangPrettyPrinter >> visitDeclarator: aDeclarator [

	aDeclarator qualifiers
		do: [ :e | 
			stream nextPutAll: e.
			stream space ].
	
	aDeclarator pointers
		do: [ :e | stream nextPutAll: e ].
	
	aDeclarator declarator acceptVisitor: self
]

{ #category : #generated }
CSlangPrettyPrinter >> visitDecrement: anDecrementNode [
	| visit |
	visit := [ anDecrementNode object acceptVisitor: self ].
	anDecrementNode prefix ifFalse: visit.
	stream nextPutAll: '--'.
	anDecrementNode prefix ifTrue: visit.
]

{ #category : #generated }
CSlangPrettyPrinter >> visitDoStatement: aDoStatement [

	stream nextPutAll: 'do'.
	aDoStatement statement acceptVisitor: self.
	stream nextPutAll: 'while('.
	aDoStatement while acceptVisitor: self.
	stream nextPutAll: ');'
]

{ #category : #generated }
CSlangPrettyPrinter >> visitForStatement: aForStatement [

	stream nextPutAll: 'for('.
	aForStatement init acceptVisitor: self.
	stream nextPutAll: '; '.
	aForStatement until acceptVisitor: self.
	stream nextPutAll: '; '.
	aForStatement step acceptVisitor: self.
	stream nextPutAll: ') '.
	aForStatement statement acceptVisitor: self.
]

{ #category : #generated }
CSlangPrettyPrinter >> visitGotoStatement: aGoToStatement [

	stream nextPutAll: 'goto ';
			 nextPutAll: aGoToStatement label name
	
]

{ #category : #generated }
CSlangPrettyPrinter >> visitIdentifier: anIdentifier [

	stream nextPutAll: anIdentifier name
]

{ #category : #generated }
CSlangPrettyPrinter >> visitIfStatement: anIf [

	stream nextPutAll: 'if ('.
	anIf if acceptVisitor: self.
	stream nextPutAll: ') '.
	anIf then acceptVisitor: self.
	anIf else ifNotNil: [ :e | 
		stream nextPutAll: 'else '.
		e acceptVisitor: self ]
]

{ #category : #generated }
CSlangPrettyPrinter >> visitIncrement: anIncrementNode [
	| visit |
	visit := [ anIncrementNode object acceptVisitor: self ].
	anIncrementNode prefix ifFalse: visit.
	stream nextPutAll: '++'.
	anIncrementNode prefix ifTrue: visit.
]

{ #category : #generated }
CSlangPrettyPrinter >> visitInitDeclarator: anInitDeclarator [

	anInitDeclarator declarator acceptVisitor: self.
	stream nextPutAll: ' = '.
	anInitDeclarator initializer acceptVisitor: self.
]

{ #category : #generated }
CSlangPrettyPrinter >> visitInitializer: anInitializer [

	stream
		nextPut: ${;
		crtab: level + 1.
	anInitializer initializers
		do: [ :e | e acceptVisitor: self ]
		separatedBy: [ stream nextPutAll: ', ' ].
	stream crtab: level.
	stream nextPut: $}
]

{ #category : #generated }
CSlangPrettyPrinter >> visitPoint: aMemberAccess [

	aMemberAccess object acceptVisitor: self.
	stream nextPut: $..
	aMemberAccess member acceptVisitor: self
]

{ #category : #generated }
CSlangPrettyPrinter >> visitReturnStatement: aReturn [

	stream nextPutAll: 'return'.
	aReturn expression ifNotNil: [ :exp |
		stream space.
		exp acceptVisitor: self ]
]

{ #category : #generated }
CSlangPrettyPrinter >> visitStringLiteral: aStringLiteral [

	stream nextPut: $".
	stream nextPutAll: aStringLiteral value.
	stream nextPut: $"
]

{ #category : #generated }
CSlangPrettyPrinter >> visitTernary: aTarnary [

	stream nextPutAll: '(('.
	aTarnary condition acceptVisitor: self.
	stream nextPutAll: ') ? '.
	aTarnary then acceptVisitor: self.
	stream nextPutAll: ' : '.
	aTarnary else acceptVisitor: self.
	stream nextPut: $)
]

{ #category : #generated }
CSlangPrettyPrinter >> visitTypename: aTypename [

	stream nextPutAll: aTypename symbol
]

{ #category : #generated }
CSlangPrettyPrinter >> visitUnaryOperator: anUnary [

	| parenthesises |
	parenthesises := anUnary expression isConstant or: [ 
		                 anUnary expression isIdentifier ].
	stream nextPutAll: anUnary operator.
	parenthesises ifFalse: [ stream nextPut: $( ].
	anUnary expression acceptVisitor: self.
	parenthesises ifFalse: [ stream nextPut: $) ]
]

{ #category : #generated }
CSlangPrettyPrinter >> visitWhileStatement: aWhileStatement [

	stream nextPutAll: 'while('.
	aWhileStatement while acceptVisitor: self.
	stream nextPutAll: ') '.
	aWhileStatement statement acceptVisitor: self
]

{ #category : #accessing }
CSlangPrettyPrinter >> writeStream: aWriteStream [

	stream := aWriteStream 
]