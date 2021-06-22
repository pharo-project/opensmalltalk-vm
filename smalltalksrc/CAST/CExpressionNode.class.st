Class {
	#name : #CExpressionNode,
	#superclass : #CGLRAbstractNode,
	#instVars : [
		'needsParentheses'
	],
	#category : #'CAST-Nodes'
}

{ #category : #combining }
CExpressionNode >> , anotherExpression [
	
	^ anotherExpression combineWithExpression: self
]

{ #category : #generated }
CExpressionNode >> acceptVisitor: anAbstractVisitor [
	^ anAbstractVisitor visitExpression: self
]

{ #category : #combining }
CExpressionNode >> combineWithExpression: firstExpression [
	
	| result |
	result := CExpressionListNode new.
	result add: firstExpression.
	result add: self.
	^ result
]

{ #category : #initialization }
CExpressionNode >> initialize [
	
	needsParentheses := false
]

{ #category : #testing }
CExpressionNode >> isExpression [

	^ true
]

{ #category : #accessing }
CExpressionNode >> needsParentheses [

	^ needsParentheses
]

{ #category : #accessing }
CExpressionNode >> needsParentheses: aBoolean [

	needsParentheses := aBoolean
]