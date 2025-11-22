export interface User {
  uid: string;
  email: string;
  displayName?: string;
  roles: ('admin' | 'user')[];
  createdAt: Date | any;
}
