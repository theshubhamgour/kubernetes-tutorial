apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
 name: books.demo.example.com
spec:
 group: demo.example.com
 scope: Namespaced
 names:
  plural: books
  singular: book
  kind: Book
 versions:
  - name: v1
    served: true
    storage: true
    schema:
     openAPIV3Schema:
      type: object
      properties:
       spec:
        type: object
        properties:
         bookName:
          type: string
         author:
           type: string
         pages:
          type: integer
